WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        MAX(CASE WHEN c.nr_order = 1 THEN a.name END) AS main_actor
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        MAX(ct.kind) AS main_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
TitleKeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResult AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        md.main_actor,
        COALESCE(cd.companies, 'N/A') AS companies,
        cd.main_company_type,
        COALESCE(tkd.keywords, 'No Keywords') AS keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN 
        TitleKeywordDetails tkd ON md.movie_id = tkd.movie_id
)
SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY production_year DESC, total_cast DESC) AS rank,
    CASE 
        WHEN total_cast = 0 THEN 'No Cast Information'
        ELSE 'Has Cast'
    END AS cast_info_status,
    CASE 
        WHEN production_year IS NULL THEN 'Year Unknown'
        ELSE CONCAT('Released in ', production_year)
    END AS release_info
FROM 
    FinalResult
WHERE 
    title ILIKE '%Mystery%' OR
    total_cast > (SELECT AVG(total_cast) FROM MovieDetails) -- Comparison against average cast size
ORDER BY 
    production_year DESC;
This SQL query is structured comprehensively to benchmark performance through multiple advanced SQL concepts. It combines Common Table Expressions (CTEs), complex aggregations, outer joins, and window functions along with various conditional statements to yield an insightful result set, while providing the means to investigate the relationships and characteristics of films within the schema.
