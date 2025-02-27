WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notable_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
),
avg_movie_info AS (
    SELECT 
        production_year,
        AVG(movie_count) AS avg_movie_count,
        AVG(notable_roles) AS avg_notable_roles
    FROM 
        actor_info a
    JOIN 
        movie_hierarchy mh ON a.movie_count > 5
    GROUP BY 
        production_year
)

SELECT 
    mh.title,
    mh.production_year,
    ai.actor_name,
    ai.movie_count,
    ai.notable_roles,
    ami.avg_movie_count,
    ami.avg_notable_roles
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    actor_info ai ON ci.person_id = (SELECT person_id FROM aka_name WHERE name = ai.actor_name LIMIT 1)
LEFT JOIN 
    avg_movie_info ami ON mh.production_year = ami.production_year
WHERE 
    mh.level <= 2
ORDER BY 
    mh.production_year DESC, ai.movie_count DESC;

This SQL query does the following:

1. **Recursive CTE (movie_hierarchy)**: Builds a hierarchy of movies released between 2000 and 2020, including links to related titles.
  
2. **Actor Information CTE (actor_info)**: Aggregates data about actors, counting the number of movies they acted in and how many notable roles they have, where 'notable' roles are defined by the presence of a non-null note.

3. **Average Movie Information CTE (avg_movie_info)**: Calculates the average counts of movies and notable roles by production year for actors involved in more than five movies.

4. **Final Selection**: Combines the hierarchical movie information with the cast information and average metrics, applying filters to return only movies from the hierarchy up to level 2 and ordering by production year and actor's movie count.

The query effectively demonstrates various advanced SQL constructs, such as recursive queries, aggregation, outer joins, and case statements, catering to performance benchmarking by joining extensively across multiple tables.
