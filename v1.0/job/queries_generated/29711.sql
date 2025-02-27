WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'N/A') AS aka_names,
        COALESCE(SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT p.id) AS cast_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        person_info p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keyword_count,
    coalesce(cd.cast_count, 0) AS cast_count,
    coalesce(cd.roles, 'No roles listed') AS roles
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
