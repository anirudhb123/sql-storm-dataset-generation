WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        string_agg(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
MovieSummary AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        cd.company_names,
        cd.company_type,
        md.cast_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.production_year = cd.movie_id
)
SELECT 
    production_year,
    STRING_AGG(DISTINCT movie_title, '; ') AS titles,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_names, '; ') AS associated_companies,
    STRING_AGG(DISTINCT cast_names, '; ') AS cast_list
FROM 
    MovieSummary
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
