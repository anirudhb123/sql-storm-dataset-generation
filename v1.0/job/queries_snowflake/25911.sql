WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
popular_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        ROW_NUMBER() OVER (ORDER BY rm.actor_count DESC) AS rank
    FROM 
        ranked_movies rm
    WHERE 
        rm.actor_count > 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    pm.title,
    pm.production_year,
    pm.actor_count,
    pm.actor_names,
    mk.keywords,
    CASE 
        WHEN pm.production_year < 2000 THEN 'Classic'
        WHEN pm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    popular_movies pm
LEFT JOIN 
    movie_keywords mk ON pm.movie_id = mk.movie_id
WHERE 
    pm.rank <= 10
ORDER BY 
    pm.actor_count DESC, pm.title;
