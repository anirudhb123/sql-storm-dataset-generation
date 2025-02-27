WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.kind_id) AS company_kinds,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
actor_details AS (
    SELECT 
        a.person_id, 
        a.name,
        GROUP_CONCAT(DISTINCT r.role) AS roles,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ad.name AS actor_name,
    ad.roles,
    ad.movie_count,
    md.company_kinds,
    md.keywords
FROM 
    movie_details md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    actor_details ad ON cc.subject_id = ad.person_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    ad.movie_count DESC
LIMIT 10;
