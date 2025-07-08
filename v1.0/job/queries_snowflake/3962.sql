WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), movie_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.role_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), top_performers AS (
    SELECT 
        m.movie_id,
        m.role,
        m.role_count,
        RANK() OVER (PARTITION BY m.movie_id ORDER BY m.role_count DESC) AS rank
    FROM 
        movie_roles m
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(tp.role, 'No Role') AS principal_role,
    COALESCE(tp.role_count, 0) AS principal_role_count,
    a.name AS actor_name,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    ranked_movies rm
LEFT JOIN 
    complete_cast cc ON rm.title_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    top_performers tp ON rm.title_id = tp.movie_id AND tp.rank = 1
LEFT JOIN 
    movie_keyword mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.production_year IS NOT NULL
GROUP BY 
    rm.title_id, rm.title, rm.production_year, tp.role, tp.role_count, a.name
ORDER BY 
    rm.production_year DESC, keyword_count DESC;
