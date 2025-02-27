WITH recursive cte_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Description') AS movie_description,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY mi.info_type_id) AS desc_order
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
), cte_top_actors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(*) > 1
), cte_movies_actors AS (
    SELECT 
        cti.movie_id,
        cti.actor_name,
        ROW_NUMBER() OVER (PARTITION BY cti.movie_id ORDER BY cti.actor_count DESC) AS actor_rank
    FROM 
        cte_top_actors cti
    WHERE 
        cti.actor_count > (SELECT AVG(actor_count) FROM cte_top_actors)
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.movie_description,
    COALESCE(a.actor_name, 'No Top Actor') AS top_actor,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    NULLIF(SUM(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END), 0) AS classic_count
FROM 
    cte_movie_info m
LEFT JOIN 
    cte_movies_actors a ON m.movie_id = a.movie_id AND a.actor_rank = 1
GROUP BY 
    m.movie_id, m.title, m.production_year, m.movie_description, a.actor_name
ORDER BY 
    m.production_year DESC, classic_count NULLS LAST
LIMIT 10
UNION ALL
SELECT 
    mi.id AS movie_id,
    mi.title,
    mi.production_year,
    'Special Movie Info' AS movie_description,
    'Special Actor' AS top_actor,
    'N/A' AS era,
    NULL AS classic_count
FROM 
    movie_info mi
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Special%')
ORDER BY 
    movie_id DESC
LIMIT 5;
