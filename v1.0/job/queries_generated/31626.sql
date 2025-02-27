WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select movies from title table
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        0 AS level
    FROM title t

    UNION ALL

    -- Recursive case: join with movie_link to create hierarchy
    SELECT 
        ml.linked_movie_id AS movie_id,
        nt.title,
        nt.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title nt ON ml.linked_movie_id = nt.id
),
movie_statistics AS (
    SELECT 
        th.production_year,
        COUNT(DISTINCT th.movie_id) AS total_movies,
        AVG(CASE WHEN th.level = 0 THEN 1 ELSE 0 END) AS avg_base_movies,
        SUM(CASE WHEN th.production_year = 2023 THEN 1 ELSE 0 END) AS count_2023_movies
    FROM movie_hierarchy th
    GROUP BY th.production_year
),
actor_performance AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_flag
    FROM aka_name ak
    LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
    GROUP BY ak.id, ak.name
),
most_frequent_actors AS (
    SELECT 
        actor_id, 
        actor_name,
        ROW_NUMBER() OVER (ORDER BY movies_count DESC) AS rn
    FROM actor_performance
)
SELECT 
    ms.production_year,
    ms.total_movies,
    ms.avg_base_movies,
    ms.count_2023_movies,
    mf.actor_name,
    mf.movies_count
FROM movie_statistics ms
LEFT JOIN most_frequent_actors mf ON ms.total_movies > 5
WHERE mf.rn <= 10
ORDER BY ms.production_year DESC, mf.movies_count DESC;

