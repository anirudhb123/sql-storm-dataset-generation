WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.kind_id) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastRoleStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_present
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TitleCompanyStats AS (
    SELECT 
        mt.movie_id,
        COALESCE(SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END), 0) AS production_company_count,
        COALESCE(SUM(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END), 0) AS distributor_company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    kc.keyword_count,
    cs.distinct_cast_count,
    cs.avg_note_present,
    tcs.production_company_count,
    tcs.distributor_company_count,
    CASE 
        WHEN kc.keyword_count > 5 THEN 'High Keyword'
        WHEN kc.keyword_count BETWEEN 3 AND 5 THEN 'Medium Keyword'
        ELSE 'Low Keyword'
    END AS keyword_category
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordCounts kc ON rm.movie_id = kc.movie_id
LEFT JOIN 
    CastRoleStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    TitleCompanyStats tcs ON rm.movie_id = tcs.movie_id
WHERE 
    (rm.movie_count > 20 OR cs.distinct_cast_count > 10)
    AND (rm.production_year IS NOT NULL AND rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
