
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS aggregated_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

movie_info_cte AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mii.info, '; ') WITHIN GROUP (ORDER BY mii.info) AS movie_details
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    COALESCE(mk.aggregated_keywords, 'No keywords') AS keywords,
    COALESCE(mi.movie_details, 'No additional info') AS additional_info
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_cte mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
