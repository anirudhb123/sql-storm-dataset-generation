
WITH movie_actor AS (
    SELECT 
        t.title,
        a.name AS actor_name,
        t.production_year,
        t.kind_id,
        COUNT(CASE WHEN c.note IS NOT NULL THEN 1 END) AS notes_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, a.name, t.production_year, t.kind_id
),
actor_role AS (
    SELECT 
        a.name AS actor,
        r.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name, r.role
    HAVING 
        COUNT(*) > 5
),
movie_info_summary AS (
    SELECT 
        m.title,
        COALESCE(mc.note, 'No Notes') AS company_note,
        STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.title, mc.note
)
SELECT 
    ma.title,
    ma.actor_name,
    ma.production_year,
    ma.notes_count,
    ma.keywords,
    ar.role,
    ar.role_count,
    mis.company_note,
    mis.additional_info
FROM 
    movie_actor ma
JOIN 
    actor_role ar ON ma.actor_name = ar.actor
LEFT JOIN 
    movie_info_summary mis ON ma.title = mis.title
ORDER BY 
    ma.production_year DESC, ma.notes_count DESC, ar.role_count DESC
LIMIT 100;
