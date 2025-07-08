WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.id DESC) AS year_rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast m ON t.id = m.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) as company_order
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ci.company_name, 'Independent') AS company,
    COALESCE(ci.company_type, 'N/A') AS company_type,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN rm.cast_count > 5 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    AVG(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_filled
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id AND ci.company_order = 1
LEFT JOIN 
    KeywordCount kc ON rm.movie_id = kc.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = rm.movie_id
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ci.company_name, ci.company_type, kc.keyword_count, rm.cast_count
ORDER BY 
    rm.production_year DESC, cast_size;
