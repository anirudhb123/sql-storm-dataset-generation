WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        p.name AS person_name,
        r.role AS role,
        t.title AS movie_title,
        t.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    md.movie_title,
    md.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cd.person_name || ' (' || cd.role || ')', ', ') AS cast_information,
    STRING_AGG(DISTINCT mc.company_name, ', ') AS production_companies
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_title = cd.movie_title AND md.production_year = cd.production_year
GROUP BY 
    md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;
