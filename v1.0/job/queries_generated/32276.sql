WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    a.imdb_index AS actor_index,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy AS mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND a.surname_pcode IS NULL
    AND mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.id, a.name, a.imdb_index
ORDER BY 
    total_movies DESC, avg_production_year DESC;
