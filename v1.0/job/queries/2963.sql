WITH MovieDetails AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        at.id, at.title, at.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalReport AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        md.null_notes_count,
        ci.companies,
        ci.company_count,
        ki.keywords,
        ki.keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyInfo ci ON md.production_year = ci.movie_id
    LEFT JOIN 
        KeywordInfo ki ON md.production_year = ki.movie_id
)
SELECT 
    *,
    CASE 
        WHEN cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status,
    ROW_NUMBER() OVER (ORDER BY production_year DESC, title ASC) AS row_num
FROM 
    FinalReport
WHERE 
    cast_count > 0
ORDER BY 
    production_year DESC, cast_count DESC;
