WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS level
    FROM
        title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id AS title_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        th.level + 1
    FROM
        movie_link m
    JOIN title mt ON m.linked_movie_id = mt.id
    JOIN title_hierarchy th ON m.movie_id = th.title_id
    WHERE 
        th.level < 3
),
top_movies AS (
    SELECT 
        th.title,
        th.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        title_hierarchy th
    LEFT JOIN complete_cast cc ON th.title_id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY 
        th.title, th.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies,
        COUNT(mt.id) AS movie_count
    FROM 
        aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title mt ON ci.movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        a.id, a.name
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ai.name AS actor_name,
    ai.movies,
    ai.movie_count
FROM 
    top_movies tm
LEFT JOIN actor_info ai ON tm.title = ANY(STRING_TO_ARRAY(ai.movies, ', '))
ORDER BY 
    tm.cast_count DESC, 
    ai.movie_count DESC;
