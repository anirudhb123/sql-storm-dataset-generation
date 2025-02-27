WITH movie_details AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        a.name AS actor_name, 
        c.kind AS cast_type
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    WHERE 
        t.production_year >= 2000
), actor_counts AS (
    SELECT 
        title_id, 
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        title_id
), keyword_counts AS (
    SELECT 
        title_id, 
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        movie_details
    GROUP BY 
        title_id
)
SELECT 
    md.title_id, 
    md.title, 
    md.production_year, 
    ac.actor_count, 
    kc.keywords
FROM 
    movie_details md
JOIN 
    actor_counts ac ON md.title_id = ac.title_id
JOIN 
    keyword_counts kc ON md.title_id = kc.title_id
ORDER BY 
    md.production_year DESC, 
    ac.actor_count DESC
LIMIT 50;
