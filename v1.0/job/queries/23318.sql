
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC, t.title) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(STRING_AGG(DISTINCT ci.note, ', '), 'No roles') AS cast_notes,
        COALESCE(cmp.company_name, 'Unknown Company') AS production_company,
        COALESCE(cmp.company_type, 'Unknown Type') AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyInfo cmp ON rm.movie_id = cmp.movie_id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mk.keywords, cmp.company_name, cmp.company_type
)

SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    cast_notes,
    production_company, 
    company_type
FROM 
    MovieDetails
WHERE 
    (production_year BETWEEN 1990 AND 2020)
    AND (keywords IS NOT NULL OR production_company <> 'Unknown Company')
    AND NOT (production_company IS NULL AND company_type IS NULL)
ORDER BY 
    production_year DESC,
    title ASC;
