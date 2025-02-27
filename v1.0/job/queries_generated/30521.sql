WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM
        title mt
    LEFT JOIN
        movie_link ml ON mt.id = ml.movie_id
    WHERE
        mt.production_year > 2000  -- filter to only consider more recent movies

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    WHERE 
        level < 3  -- limit the recursion to 3 levels
),

actor_movies AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        mt.production_year,
        COUNT(DISTINCT mi.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title mt ON ci.movie_id = mt.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        a.id, ak.name, mt.production_year
),

joined_data AS (
    SELECT 
        mh.title AS movie_title,
        mh.production_year,
        am.actor_name,
        am.movie_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        movie_hierarchy mh
    JOIN 
        actor_movies am ON mh.movie_id = am.movie_id
)

SELECT 
    jd.movie_title,
    jd.production_year,
    jd.actor_name,
    jd.movie_count,
    jd.year_rank
FROM 
    joined_data jd
WHERE 
    jd.year_rank <= 5  -- limit to top 5 actors per year
ORDER BY 
    jd.production_year DESC, jd.movie_count DESC;


This SQL query performs several complex operations and includes:

1. A recursive CTE (`movie_hierarchy`) to build a hierarchy of linked movies produced after 2000.
2. An aggregate in `actor_movies` that counts the movies each actor appeared in, filtered by whether box office information exists.
3. A final selection that combines the information, calculating a row number to rank the results by production year and movie count.
4. It includes NULL checks to ensure data integrity.
5. The use of a `ROW_NUMBER()` window function allows ordering and limiting results per year.
This query can serve well for performance benchmarking while showcasing complex SQL features.
