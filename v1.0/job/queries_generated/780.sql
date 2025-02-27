WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title, 
        mt.production_year, 
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_count
    FROM
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        cast_info ci ON mk.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.title, mt.production_year, ak.name
),
actor_movie_stats AS (
    SELECT 
        am.movie_id, 
        COUNT(DISTINCT ak.person_id) AS distinct_actor_count,
        SUM(CASE WHEN ak.name IS NOT NULL THEN 1 ELSE 0 END) AS non_null_actor_count
    FROM 
        cast_info am
    LEFT JOIN 
        aka_name ak ON am.person_id = ak.person_id
    GROUP BY 
        am.movie_id
),
title_info AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, t.production_year, t.kind_id
)
SELECT 
    rm.movie_title, 
    rm.production_year, 
    ts.title, 
    ts.keyword_count,
    ams.distinct_actor_count,
    ams.non_null_actor_count
FROM 
    ranked_movies rm
JOIN 
    title_info ts ON rm.movie_title = ts.title AND rm.production_year = ts.production_year
JOIN 
    actor_movie_stats ams ON ts.title = ams.movie_id
WHERE 
    rm.rank_by_cast_count <= 5
ORDER BY 
    rm.production_year DESC, 
    ts.keyword_count DESC;
