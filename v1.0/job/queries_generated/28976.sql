WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
actor_roles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.movie_id, r.role
),
top_actors AS (
    SELECT 
        person_id,
        SUM(role_count) AS total_roles
    FROM 
        actor_roles
    GROUP BY 
        person_id
    ORDER BY 
        total_roles DESC
    LIMIT 10
),
final_selection AS (
    SELECT 
        t.title,
        t.production_year,
        a.name,
        at.role_name,
        rt.keyword
    FROM 
        ranked_titles rt
    JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        top_actors ta ON ta.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON rt.title_id = mi.movie_id
    WHERE 
        (mi.info IS NULL OR mi.info NOT LIKE '%blockbuster%')
)
SELECT 
    title,
    production_year,
    name AS actor_name,
    role_name,
    STRING_AGG(keyword, ', ') AS keywords
FROM 
    final_selection
GROUP BY 
    title, production_year, actor_name, role_name
ORDER BY 
    production_year DESC, title;
