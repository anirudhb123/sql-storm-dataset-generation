WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name LIKE '%Smith%' -- Benchmark for name processing
), movie_keywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
), company_movie_info AS (
    SELECT 
        t.title AS movie_title,
        cn.name AS company_name,
        ct.kind AS company_type,
        mi.info AS movie_information
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        ct.kind = 'Production' -- Focus on production companies
)
SELECT 
    ma.actor_name,
    ma.movie_title,
    ma.production_year,
    ma.actor_role,
    mk.movie_keyword,
    cm.company_name,
    cm.company_type,
    cm.movie_information
FROM 
    movie_actors ma
LEFT JOIN 
    movie_keywords mk ON ma.movie_title = mk.movie_title
LEFT JOIN 
    company_movie_info cm ON ma.movie_title = cm.movie_title
ORDER BY 
    ma.production_year DESC, ma.actor_name, mk.movie_keyword;
