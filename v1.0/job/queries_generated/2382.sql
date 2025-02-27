WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(ct.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ct ON cc.subject_id = ct.id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count,
        AVG(strlen(ak.name)) AS avg_name_length
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        ai.actor_name,
        ai.movies_count,
        ai.avg_name_length
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_info ai ON ai.movies_count > 5
    WHERE 
        rm.production_year BETWEEN 2000 AND 2020
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.title_rank,
    f.actor_name,
    COALESCE(f.movies_count, 0) AS movies_count,
    COALESCE(f.avg_name_length, 0) AS avg_name_length
FROM 
    filtered_movies f
WHERE 
    f.title_rank <= 10
ORDER BY 
    f.production_year DESC, 
    f.title;
