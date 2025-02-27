WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT c.kind_id::text, ', ') AS company_types,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
CastDetails AS (
    SELECT 
        DISTINCT ci.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.company_types,
    md.keywords,
    cd.actors,
    cd.roles
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title ASC;
