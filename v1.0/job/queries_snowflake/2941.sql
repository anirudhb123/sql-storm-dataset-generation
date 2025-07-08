
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ai.actor_count, 0) AS total_actors,
    COALESCE(ai.actor_names, 'No actors listed') AS actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.year_rank = 1 THEN 'Most Recent'
        ELSE 'Other'
    END AS movie_classification
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_info ai ON rm.movie_id = ai.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.title;
