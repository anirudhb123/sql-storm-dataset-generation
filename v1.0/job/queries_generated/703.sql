WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
)
SELECT 
    t.title,
    t.production_year,
    ar.role,
    ar.actor_count,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = t.id) AS total_cast,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
    CASE 
        WHEN ar.actor_count IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS actor_status
FROM 
    ranked_titles t
LEFT JOIN 
    actor_roles ar ON t.id = ar.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.title_rank <= 5
ORDER BY 
    t.production_year DESC, actor_count DESC
LIMIT 50;
