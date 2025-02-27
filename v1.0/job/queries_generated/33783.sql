WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    co.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT ah.name, ', ') AS actors_list,
    AVG(CASE 
            WHEN mt.production_year IS NOT NULL THEN EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year 
            ELSE NULL 
            END) AS avg_movie_age,
    SUM(CASE 
            WHEN ci.note IS NULL THEN 1 
            ELSE 0 
        END) AS null_note_count
FROM 
    movie_companies AS mc
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    complete_cast AS cc ON mc.movie_id = cc.movie_id
JOIN 
    aka_name AS ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    MovieHierarchy AS mh ON mc.movie_id = mh.movie_id
LEFT JOIN 
    aka_title AS mt ON cc.movie_id = mt.id
WHERE 
    co.country_code IS NOT NULL
GROUP BY 
    co.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC;
