
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.company_types,
    md.cast_count,
    cd.actors,
    cd.roles
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC;
