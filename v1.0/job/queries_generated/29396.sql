WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, a.id, r.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        count(*) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
final_benchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.actor_role,
        md.keywords,
        cd.company_name,
        cd.company_type,
        cd.total_movies
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_title = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_role,
    keywords,
    company_name,
    company_type,
    total_movies
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, 
    movie_title;
