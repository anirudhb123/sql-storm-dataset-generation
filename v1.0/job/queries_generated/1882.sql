WITH movie_cast AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        p2.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    LEFT JOIN 
        cast_info c2 ON mc.movie_id = c2.movie_id AND c2.person_role_id = (SELECT id FROM role_type WHERE role = 'Director') 
    JOIN 
        aka_name p2 ON c2.person_id = p2.person_id
),
top_movies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN km.keyword = 'Action' THEN 1 ELSE 0 END) AS action_movie_flag
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1
    ORDER BY 
        company_count DESC
    LIMIT 10
)
SELECT 
    mc.movie_id,
    mc.actor_name,
    mc.director_name,
    tm.title,
    tm.production_year,
    tm.company_count,
    CASE 
        WHEN tm.action_movie_flag > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS is_action_movie
FROM 
    movie_cast mc
JOIN 
    top_movies tm ON mc.movie_id = tm.movie_id
WHERE 
    mc.role_order <= 3
ORDER BY 
    tm.production_year DESC, 
    mc.actor_name;
