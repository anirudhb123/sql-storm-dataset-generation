WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FinalStats AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword_count,
        COALESCE(cs.company_count, 0) AS company_count,
        COALESCE(cs.company_type_count, 0) AS company_type_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyStats cs ON md.title_id = cs.movie_id
)
SELECT 
    title,
    production_year,
    cast_names,
    keyword_count,
    company_count,
    company_type_count,
    CASE 
        WHEN company_count > 0 THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_presence,
    RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS keyword_rank
FROM 
    FinalStats
WHERE 
    cast_names IS NOT NULL
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
