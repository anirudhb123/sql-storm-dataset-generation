WITH movie_ratings AS (
    SELECT 
        m.title,
        AVG(r.rating) AS avg_rating
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT 
            movie_id,
            rating
         FROM 
            movie_info 
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        ) r ON m.id = r.movie_id
    GROUP BY 
        m.title
),
cast_details AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
company_movie_counts AS (
    SELECT 
        cm.company_id,
        COUNT(m.id) AS movie_count
    FROM 
        movie_companies cm
    JOIN 
        movie_info mi ON cm.movie_id = mi.movie_id
    GROUP BY 
        cm.company_id
)
SELECT 
    cd.actor_name,
    cd.movie_title,
    mr.avg_rating,
    cmc.movie_count,
    CASE 
        WHEN mr.avg_rating IS NULL THEN 'No Rating'
        ELSE mr.avg_rating::text 
    END AS rating_status
FROM 
    cast_details cd
LEFT JOIN 
    movie_ratings mr ON cd.movie_title = mr.title
LEFT JOIN 
    company_movie_counts cmc ON cmc.company_id = (SELECT company_id FROM movie_companies WHERE movie_id = (SELECT id FROM title WHERE title = cd.movie_title) LIMIT 1)
WHERE 
    mr.avg_rating IS NOT NULL OR cmc.movie_count > 0
ORDER BY 
    cd.role_order, mr.avg_rating DESC NULLS LAST;
