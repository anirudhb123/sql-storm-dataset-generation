WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT co.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        co.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
KeyWords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, '; ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.total_cast, 0) AS total_cast,
    COALESCE(md.cast_names, 'No Cast Available') AS cast_names,
    COALESCE(cd.companies, 'No Companies Available') AS companies,
    COALESCE(cd.total_companies, 0) AS total_companies,
    COALESCE(k.keywords, 'No Keywords Available') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    KeyWords k ON md.movie_id = k.movie_id
WHERE 
    md.total_cast > 0 OR cd.total_companies > 0
ORDER BY 
    md.production_year DESC, md.title;
