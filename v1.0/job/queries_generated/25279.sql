WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        string_agg(DISTINCT c.kind, ', ') AS company_types
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type c ON c.id = mc.company_type_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        string_agg(DISTINCT ak.name, ', ') AS actor_names,
        string_agg(DISTINCT rt.role, ', ') AS role_types
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    cd.actor_names,
    cd.role_types,
    md.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON cd.movie_id = md.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC;
