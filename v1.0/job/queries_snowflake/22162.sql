
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT a.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actors
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
        ARRAY_AGG(mk.keyword_id) AS keyword_ids,
        CASE 
            WHEN COUNT(mk.keyword_id) > 0 THEN 'Has Keywords'
            ELSE 'No Keywords'
        END AS keyword_status
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
movie_information AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Synopsis' THEN mi.info END) AS synopsis,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'Revenue' THEN mi.info END) AS revenue
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mc.actor_count, 0) AS actor_count,
        COALESCE(mk.keyword_ids, ARRAY_CONSTRUCT()) AS keyword_ids,
        mi.synopsis,
        mi.budget,
        mi.revenue,
        RANK() OVER (ORDER BY COALESCE(mi.revenue::numeric, 0) DESC) AS revenue_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_cast mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_information mi ON m.id = mi.movie_id
)
SELECT 
    rm.title,
    rm.actor_count,
    rm.keyword_ids,
    rm.synopsis,
    rm.budget,
    rm.revenue,
    CASE 
        WHEN rm.revenue_rank <= 10 THEN 'Top 10 Revenue'
        ELSE 'Lower Revenue'
    END AS revenue_category,
    CASE 
        WHEN rm.budget IS NULL THEN 'Budget Info Not Available'
        WHEN rm.budget = '' THEN 'Budget Not Specified'
        ELSE 'Budget Info Available'
    END AS budget_availability
FROM 
    ranked_movies rm
WHERE 
    rm.keyword_ids IS NOT NULL
    AND rm.actor_count > 2
ORDER BY 
    revenue_rank ASC
LIMIT 20;
