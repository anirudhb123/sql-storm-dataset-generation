WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT k.keyword, ', ') as keywords,
        string_agg(DISTINCT c.name, ', ') as companies
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
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        t.movie_id,
        string_agg(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        complete_cast t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id 
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    cd.actors,
    cd.role_count
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000 
ORDER BY 
    md.production_year DESC,
    md.title ASC;
