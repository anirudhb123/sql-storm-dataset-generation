WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id DESC) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),

MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(CAST(COUNT(DISTINCT ci.person_id) AS INTEGER), 0) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notable_cast
    FROM 
        RankedMovies r
    LEFT JOIN 
        complete_cast cc ON r.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        r.movie_id, r.title, r.production_year
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.notable_cast,
    COALESCE(ci.company_count, 0) AS company_count,
    COALESCE(ci.company_names, 'None') AS company_names
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
WHERE 
    (md.cast_count > 5 OR ci.company_count > 2)
    AND (md.production_year IS NOT NULL OR ci.company_count IS NULL)
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
