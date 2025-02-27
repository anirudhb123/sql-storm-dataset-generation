
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
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
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    COALESCE(md.cast_count, 0) AS total_cast,
    COALESCE(cd.companies, 'None') AS companies,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    COALESCE(kw.keywords, 'No keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kw ON md.movie_id = kw.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, total_cast DESC;
