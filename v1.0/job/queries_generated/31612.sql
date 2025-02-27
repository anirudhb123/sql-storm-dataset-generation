WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(a.name, 'Unknown') AS actor_name,
        1 AS depth
    FROM
        aka_title AS m
    LEFT JOIN
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name AS a ON ci.person_id = a.person_id
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        COALESCE(a.name, 'Unknown') AS actor_name,
        depth + 1
    FROM
        MovieHierarchy AS mh
    JOIN
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title AS m ON ml.linked_movie_id = m.id
    LEFT JOIN
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name AS a ON ci.person_id = a.person_id
    WHERE
        m.production_year >= 2000
)

SELECT
    mh.title,
    STRING_AGG(DISTINCT mh.actor_name, ', ') AS actors,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(CASE 
        WHEN m.production_year IS NOT NULL THEN m.production_year
        ELSE NULL 
    END) AS average_production_year,
    COUNT(DISTINCT CASE 
        WHEN ci.role_id IS NULL THEN NULL 
        ELSE ci.role_id 
    END) AS unique_roles_count
FROM
    MovieHierarchy AS mh
LEFT JOIN
    aka_title AS m ON mh.movie_id = m.id
LEFT JOIN 
    cast_info AS ci ON mh.movie_id = ci.movie_id
GROUP BY 
    mh.title
HAVING 
    COUNT(DISTINCT mh.actor_name) > 3
ORDER BY 
    average_production_year DESC;
