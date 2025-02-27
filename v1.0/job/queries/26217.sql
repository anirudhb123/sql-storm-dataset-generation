WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
actor_movies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
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
),
movie_info_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, '; ') AS info_summary
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx m ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    am.actor_count,
    mk.keywords,
    mis.info_summary
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_movies am ON rm.movie_id = am.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_summary mis ON rm.movie_id = mis.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC,
    rm.title;
