WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(SUM(CASE WHEN LENGTH(k.keyword) > 10 THEN 1 ELSE 0 END), 0) AS long_keywords_count
    FROM 
        title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompanyStatistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS unique_company_count,
        STRING_AGG(DISTINCT CONCAT(c.name, ' (', ct.kind, ')'), ', ') AS company_details
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.cast_list,
    rm.total_cast,
    rm.keywords,
    rm.long_keywords_count,
    cs.unique_company_count,
    cs.company_details
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStatistics cs ON rm.movie_id = cs.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
