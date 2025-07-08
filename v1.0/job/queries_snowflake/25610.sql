WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(c.name, 'No Company') AS company,
        COALESCE(a.name, 'Unknown Actor') AS actor,
        COALESCE(rt.role, 'Role Not Specified') AS role,
        m.production_year,
        COALESCE(a.id, 0) AS actor_id
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        m.production_year >= 2000  
), actor_counts AS (
    
    SELECT 
        actor_id,
        actor,
        COUNT(movie_id) AS movie_count
    FROM 
        movie_hierarchy
    GROUP BY 
        actor_id, actor
),
company_movie_counts AS (
    
    SELECT 
        company,
        COUNT(movie_id) AS company_movie_count
    FROM 
        movie_hierarchy
    GROUP BY 
        company
)
SELECT 
    a.actor,
    a.movie_count,
    c.company,
    c.company_movie_count,
    COUNT(k.keyword) AS keyword_count
FROM 
    actor_counts a
JOIN 
    movie_hierarchy mh ON a.actor_id = mh.actor_id
JOIN 
    company_movie_counts c ON mh.company = c.company
JOIN 
    keyword k ON mh.keyword = k.keyword
GROUP BY 
    a.actor, a.movie_count, c.company, c.company_movie_count
ORDER BY 
    a.movie_count DESC, c.company_movie_count DESC;