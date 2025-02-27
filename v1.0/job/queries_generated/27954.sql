WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        c.note AS cast_note
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND LOWER(t.title) LIKE '%adventure%'
        AND a.name IS NOT NULL
),
KeywordDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        k.keyword AS movie_keyword
    FROM 
        MovieDetails md
    JOIN 
        movie_keyword mk ON md.movie_title = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        t.title AS movie_title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind LIKE '%Production%'
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.actor_role,
    wd.movie_keyword,
    cd.company_name,
    cd.company_type
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails wd ON md.movie_title = wd.movie_title
LEFT JOIN 
    CompanyDetails cd ON md.movie_title = cd.movie_title
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
