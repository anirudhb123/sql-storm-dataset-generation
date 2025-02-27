WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank
    FROM 
        title m 
    WHERE 
        m.production_year IS NOT NULL
),
actor_details AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movies_with_actors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ad.actor_id,
        ad.actor_name,
        ad.role_name,
        rm.rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_details ad ON rm.movie_id = ad.movie_id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
final_benchmark AS (
    SELECT 
        mwa.movie_id,
        mwa.title,
        mwa.production_year,
        mwa.actor_name,
        mwa.role_name,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN mwa.rank <= 10 THEN 'Top 10 Movies of the Year'
            ELSE 'Other Movies'
        END AS movie_category
    FROM 
        movies_with_actors mwa
    LEFT JOIN 
        keyword_counts kc ON mwa.movie_id = kc.movie_id
)
SELECT 
    movie_category,
    COUNT(*) AS total_movies,
    AVG(keyword_count) AS avg_keywords,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors_in_movies
FROM 
    final_benchmark
GROUP BY 
    movie_category
ORDER BY 
    total_movies DESC;
