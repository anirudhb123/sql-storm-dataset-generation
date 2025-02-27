WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN LENGTH(ci.note) END) AS avg_note_length,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        aka_name cn ON cn.person_id = ci.person_id
    GROUP BY 
        mt.id
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON co.id = mc.company_id
    GROUP BY 
        mc.movie_id
), KeywordAnalysis AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.avg_note_length,
    md.cast_names,
    COALESCE(cd.total_companies, 0) AS total_companies,
    cd.company_names,
    COALESCE(ka.keyword_count, 0) AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = md.id
LEFT JOIN 
    KeywordAnalysis ka ON ka.movie_id = md.id
WHERE 
    md.production_year < 2000 
    AND md.total_cast > 5
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
