
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rank <= 3
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(company.name, 'Independent') AS company_name,
    CASE 
        WHEN fm.cast_count > 5 THEN 'Large Cast' 
        WHEN fm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size,
    (SELECT AVG(fm2.cast_count) FROM FilteredMovies fm2 WHERE fm2.production_year = fm.production_year) AS avg_cast_count_for_year
FROM FilteredMovies fm
LEFT JOIN (
    SELECT mk.movie_id, LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
) k ON fm.title_id = k.movie_id
LEFT JOIN (
    SELECT mc.movie_id, cn.name
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
) company ON fm.title_id = company.movie_id
ORDER BY fm.production_year DESC, fm.cast_count DESC;
