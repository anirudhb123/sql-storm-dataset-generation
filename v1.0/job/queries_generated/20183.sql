WITH RECURSIVE RecursiveMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.phonetic_code,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.phonetic_code,
        rm.level + 1
    FROM 
        RecursiveMovies rm
    JOIN 
        movie_link ml ON rm.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020 AND
        rm.level < 5  -- Limit depth to avoid long recursion
)

SELECT 
    lm.movie_id,
    lm.title,
    lm.production_year,
    lm.phonetic_code,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(COALESCE(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) END, 0)) AS avg_bio_length,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    RecursiveMovies lm
LEFT JOIN 
    complete_cast cc ON lm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    lm.production_year = (SELECT MAX(production_year) FROM aka_title WHERE kind_id = 1)
GROUP BY 
    lm.movie_id, lm.title, lm.production_year, lm.phonetic_code
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    avg_bio_length DESC NULLS LAST
LIMIT 10

OFFSET 0;

-- Additional performance considerations:
EXPLAIN ANALYZE -- To visualize the query plan for performance assessment
