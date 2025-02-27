WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
HighCastMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 3
)
SELECT 
    hcm.title, 
    hcm.production_year,
    COALESCE(mk.keyword, 'No keyword') AS keyword,
    (SELECT COUNT(DISTINCT person_id) 
     FROM person_info pi 
     WHERE pi.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id IN (SELECT movie_id FROM complete_cast cc WHERE cc.subject_id IN (SELECT id FROM aka_name WHERE name LIKE '%Smith%')))) AS smith_actors,
    string_agg(DISTINCT cn.name, ', ') AS company_names
FROM 
    HighCastMovies hcm
LEFT JOIN 
    movie_keyword mk ON hcm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    movie_companies mc ON hcm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    hcm.title, hcm.production_year, mk.keyword
HAVING 
    hcm.production_year >= 2000
ORDER BY 
    hcm.production_year DESC, hcm.title;
