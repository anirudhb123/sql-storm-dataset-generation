WITH actor_movie_counts AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id,
        a.name
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
tagged_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword_counts mkc ON mt.id = mkc.movie_id
),
combined_data AS (
    SELECT 
        amc.actor_id,
        amc.actor_name,
        tm.movie_id,
        tm.title,
        tm.keyword_count
    FROM 
        actor_movie_counts amc
    JOIN 
        cast_info ci ON amc.actor_id = ci.person_id
    JOIN 
        tagged_movies tm ON ci.movie_id = tm.movie_id
),
final_benchmark AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_appearance_count,
        SUM(keyword_count) AS total_keywords
    FROM 
        combined_data
    GROUP BY 
        actor_id, 
        actor_name
)
SELECT 
    actor_id,
    actor_name,
    movie_appearance_count,
    total_keywords,
    movie_appearance_count * total_keywords AS benchmark_score
FROM 
    final_benchmark
ORDER BY 
    benchmark_score DESC
LIMIT 10;
