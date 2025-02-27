
WITH MovieDetail AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), MovieCompanyDetail AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), KeywordDetail AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        mcd.company_names,
        mcd.total_companies,
        kd.keywords
    FROM 
        MovieDetail md
    LEFT JOIN 
        MovieCompanyDetail mcd ON md.movie_id = mcd.movie_id
    LEFT JOIN 
        KeywordDetail kd ON md.movie_id = kd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    (CASE WHEN total_cast IS NULL THEN 'No Cast' ELSE CAST(total_cast AS VARCHAR) END) AS total_cast_display,
    (CASE WHEN cast_names IS NULL THEN 'No Cast Names' ELSE cast_names END) AS cast_names_display,
    (CASE WHEN company_names IS NULL THEN 'No Companies' ELSE company_names END) AS company_names_display,
    (CASE WHEN total_companies IS NULL THEN 0 ELSE total_companies END) AS total_companies_display,
    (CASE WHEN keywords IS NULL THEN 'No Keywords' ELSE keywords END) AS keywords_display
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title ASC
LIMIT 100;
