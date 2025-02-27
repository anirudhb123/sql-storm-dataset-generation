WITH MovieMeta AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CompanyMeta AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
InfoMeta AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(m.cast_count, 0) AS total_cast,
    COALESCE(m.actors, 'No actors') AS actors_list,
    COALESCE(c.company_count, 0) AS total_companies,
    COALESCE(c.companies, 'No companies') AS companies_list,
    COALESCE(i.info_details, 'No additional info') AS additional_info
FROM 
    MovieMeta m
FULL OUTER JOIN 
    CompanyMeta c ON m.movie_id = c.movie_id
FULL OUTER JOIN 
    InfoMeta i ON m.movie_id = i.movie_id
WHERE 
    (m.production_year BETWEEN 2000 AND 2023 OR c.company_count IS NOT NULL OR i.info_details IS NOT NULL)
ORDER BY 
    m.production_year DESC, m.title;
