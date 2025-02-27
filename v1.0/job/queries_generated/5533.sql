WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        r.role AS actor_role, 
        c.note AS cast_note, 
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role, c.note
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.actor_name, 
    md.actor_role, 
    md.cast_note, 
    md.keywords
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    md.movie_id ASC;
