
WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT c.nr_order) AS cast_orders,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.kind_id,
        md.total_cast,
        md.cast_orders,
        md.actor_names,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank_by_cast,
        MAX(md.production_year) OVER () AS max_year
    FROM 
        movie_data md
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.cast_orders,
    rm.actor_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.production_year = rm.max_year THEN 'Latest Production'
        ELSE 'Earlier Production'
    END AS production_timing
FROM 
    ranked_movies rm
LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_by_cast <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
