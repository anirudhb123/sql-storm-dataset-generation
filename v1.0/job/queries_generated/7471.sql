WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords, 
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS average_cast_order
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id
),
person_details AS (
    SELECT 
        a.id AS aka_id, 
        a.name, 
        p.info, 
        a.person_id,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS average_role
    FROM 
        aka_name a
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    pd.name AS actor_name,
    pd.info AS actor_info,
    md.keywords,
    md.companies,
    md.average_cast_order,
    pd.average_role
FROM 
    movie_details md
JOIN 
    person_details pd ON pd.person_id IN (
        SELECT person_id 
        FROM cast_info 
        WHERE movie_id = md.movie_id
    )
ORDER BY 
    md.production_year DESC, 
    md.title;
