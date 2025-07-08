
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        a.name AS actor_name,
        r.role AS actor_role,
        c.name AS company_name,
        k.keyword,
        mi.info
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
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND r.role IN ('actor', 'actress')
    ORDER BY 
        t.production_year DESC, 
        a.name, 
        k.keyword
)
SELECT 
    title_id,
    title,
    production_year,
    kind_id,
    actor_name,
    actor_role,
    company_name,
    LISTAGG(DISTINCT keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords,
    LISTAGG(DISTINCT info, '; ') WITHIN GROUP (ORDER BY info) AS info_details
FROM 
    MovieDetails
GROUP BY 
    title_id, title, production_year, kind_id, actor_name, actor_role, company_name
ORDER BY 
    production_year DESC, 
    title;
