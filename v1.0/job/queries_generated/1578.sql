WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank 
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN t.production_year = 2023 THEN 1 ELSE 0 END) AS movies_2023
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.name
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ak.actor_name,
    ak.total_movies,
    ak.movies_2023,
    mk.keywords,
    COALESCE(NULLIF(ak.total_movies, 0), 0) AS safe_total_movies
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_movies ak ON rt.title_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id IN (
                SELECT 
                    t.id FROM title t WHERE t.id = rt.title_id
            )
    )
LEFT JOIN 
    movie_keywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, ak.total_movies DESC NULLS LAST;
