WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COALESCE(ac.person_id, -1), at.title) AS rn,
        COUNT(ac.person_id) OVER (PARTITION BY at.production_year) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ac ON at.movie_id = ac.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rn,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
)
SELECT 
    fm.title,
    fm.production_year,
    nm.gender,
    COUNT(mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    AVG(COALESCE(ci.nr_order, 0)) AS avg_order,
    MIN(COALESCE(cm.name, 'Unknown Company')) AS production_company
FROM 
    FilteredMovies fm
JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cm ON mc.company_id = cm.id
LEFT JOIN 
    aka_name an ON an.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = fm.movie_id)
LEFT JOIN 
    name nm ON an.person_id = nm.imdb_id
WHERE 
    nm.gender IS NOT NULL OR nm.gender IS NULL
GROUP BY 
    fm.title, fm.production_year, nm.gender
HAVING 
    COUNT(mk.keyword_id) > 0 AND 
    MIN(fm.production_year) IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.title ASC
LIMIT 50;
