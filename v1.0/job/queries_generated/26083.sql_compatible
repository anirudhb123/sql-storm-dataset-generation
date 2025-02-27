
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_size
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.keywords,
        md.cast_size,
        cd.company_names,
        cd.company_types
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)

SELECT 
    movie_title,
    production_year,
    keywords,
    cast_size,
    company_names,
    company_types
FROM 
    CompleteMovieInfo
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, 
    cast_size DESC;
