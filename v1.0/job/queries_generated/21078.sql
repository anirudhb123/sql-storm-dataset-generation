WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyCTE AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.country_code DESC NULLS LAST) AS rn
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        company_type ct ON ct.id = mc.company_type_id
),
InfoCTE AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CONCAT(it.info, ': ', mi.info), '; ') AS movie_info
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON it.id = mi.info_type_id
    GROUP BY 
        mi.movie_id
),
KeywordCTE AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mct.movie_id,
    mct.title,
    COALESCE(mct.cast_names, ARRAY[]::TEXT[]) AS cast_names,
    COALESCE(cct.company_name, 'N/A') AS production_company,
    CASE 
        WHEN kct.keyword_count IS NULL THEN 'None'
        ELSE kct.keywords 
    END AS keywords,
    COALESCE(ict.movie_info, 'No additional information') AS info_summary,
    COALESCE(mct.production_year, 'Unknown') AS year_of_production
FROM 
    MovieCTE mct
LEFT JOIN 
    CompanyCTE cct ON cct.movie_id = mct.movie_id AND cct.rn = 1
LEFT JOIN 
    InfoCTE ict ON ict.movie_id = mct.movie_id
LEFT JOIN 
    KeywordCTE kct ON kct.movie_id = mct.movie_id
WHERE 
    mct.production_year > (SELECT AVG(production_year) FROM aka_title WHERE production_year IS NOT NULL)
ORDER BY 
    mct.production_year DESC NULLS LAST, mct.title ASC;
