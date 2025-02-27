WITH MovieRoles AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        r.role AS role_name,
        t.production_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
KeywordInfo AS (
    SELECT 
        m.title AS movie_title,
        k.keyword AS keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyInfo AS (
    SELECT 
        t.title AS movie_title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CombinedInfo AS (
    SELECT 
        mr.movie_title,
        mr.actor_name,
        mr.role_name,
        mr.production_year,
        ki.keyword,
        ci.company_name,
        ci.company_type
    FROM 
        MovieRoles mr
    LEFT JOIN 
        KeywordInfo ki ON mr.movie_title = ki.movie_title
    LEFT JOIN 
        CompanyInfo ci ON mr.movie_title = ci.movie_title
)
SELECT 
    movie_title,
    actor_name,
    role_name,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', '; ') AS companies
FROM 
    CombinedInfo
GROUP BY 
    movie_title, actor_name, role_name, production_year
ORDER BY 
    production_year DESC, movie_title;
