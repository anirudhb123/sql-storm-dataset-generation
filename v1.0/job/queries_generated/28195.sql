WITH MovieList AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
CastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ca.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ca ON c.person_id = ca.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        ml.movie_id,
        ml.title,
        ml.production_year,
        ml.keyword,
        ci.total_cast,
        ci.cast_names,
        co.companies
    FROM 
        MovieList ml
    LEFT JOIN 
        CastInfo ci ON ml.movie_id = ci.movie_id
    LEFT JOIN 
        CompanyInfo co ON ml.movie_id = co.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.total_cast,
    md.cast_names,
    md.companies
FROM 
    MovieDetails md
WHERE 
    md.total_cast > 5
ORDER BY 
    md.production_year DESC, md.title;
