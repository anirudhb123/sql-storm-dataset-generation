WITH RecursiveCTE AS (
    SELECT 
        ka.id AS aka_id,
        ka.person_id,
        ka.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id 
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ka.id AS aka_id,
        ka.person_id,
        ka.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name ka
    JOIN 
        complete_cast cc ON ka.person_id = cc.subject_id
    JOIN 
        aka_title t ON cc.movie_id = t.id 
    WHERE 
        t.production_year IS NOT NULL AND 
        EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = t.id AND 
                  mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
        )
)
, TitleCount AS (
    SELECT 
        person_id,
        COUNT(DISTINCT title) AS title_count,
        MAX(production_year) AS last_movie_year
    FROM 
        RecursiveCTE
    GROUP BY 
        person_id
)
SELECT 
    ka.name,
    tc.title_count,
    COALESCE(tc.last_movie_year, 'No movies produced') AS last_movie_year,
    MAX(t.production_year) AS highest_year,
    STRING_AGG(DISTINCT t.title, ', ') AS titles
FROM 
    aka_name ka
LEFT JOIN 
    TitleCount tc ON ka.person_id = tc.person_id
LEFT JOIN 
    aka_title t ON t.id IN (SELECT movie_id FROM cast_info WHERE person_id = ka.person_id)
WHERE 
    (tc.title_count IS NULL OR tc.title_count > 1)
    AND (ka.name IS NOT NULL AND ka.name <> '')
GROUP BY 
    ka.name, tc.title_count, tc.last_movie_year
HAVING 
    COUNT(t.id) > 0
ORDER BY 
    tc.last_movie_year DESC NULLS LAST, 
    ka.name
FETCH FIRST 10 ROWS ONLY;
