
WITH MovieTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
PersonRoleInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.companies,
    p.actor_name,
    p.role,
    p.role_count
FROM 
    MovieTitleInfo m
LEFT JOIN 
    PersonRoleInfo p ON m.title_id = p.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC, 
    p.role_count DESC;
