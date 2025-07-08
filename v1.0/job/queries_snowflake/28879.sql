
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
actor_details AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT t.title) AS titles,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    ad.actor_name,
    ad.titles,
    ad.roles
FROM 
    movie_details md
JOIN 
    complete_cast cc ON md.title_id = cc.movie_id
JOIN 
    actor_details ad ON cc.subject_id = ad.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    ad.actor_name;
