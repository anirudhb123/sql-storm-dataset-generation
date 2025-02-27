WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    count(DISTINCT ch.movie_id) AS total_movies,
    max(mh.production_year) AS last_movie_year,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    row_number() OVER (PARTITION BY ak.name ORDER BY max(mh.production_year) DESC) AS actor_rank,
    CASE 
        WHEN avg(mh.level) <= 2 THEN 'Main Contributor'
        ELSE 'Supporting Role'
    END AS contributor_type
FROM 
    aka_name AS ak
LEFT JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy AS mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND mh.title IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    count(DISTINCT ch.movie_id) > 5
ORDER BY 
    total_movies DESC, last_movie_year DESC;

