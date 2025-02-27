WITH movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT n.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mc.actor_count, 0) AS actor_count,
        COALESCE(ki.keyword_count, 0) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id
    LEFT JOIN 
        keyword_info ki ON t.id = ki.movie_id
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY (actor_count + NULLIF(keyword_count, 0)) DESC, production_year DESC) AS ranking
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.keyword_count,
    CASE
        WHEN rm.actor_count > 0 AND rm.keyword_count > 0 THEN 'Well-Rounded'
        WHEN rm.actor_count = 0 AND rm.keyword_count = 0 THEN 'Unknown'
        ELSE 'Niche'
    END AS movie_category
FROM 
    ranked_movies rm
WHERE 
    rm.ranking <= 10 
ORDER BY 
    rm.ranking;
