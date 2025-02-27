
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies
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
    WHERE
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    cd.cast_count,
    cd.cast_names,
    k.kind AS movie_kind
FROM 
    MovieDetails md
JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
JOIN 
    kind_type k ON md.kind_id = k.id
WHERE 
    md.production_year = 2023
ORDER BY 
    cd.cast_count DESC, 
    md.title;
