
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS unique_companies,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names,
        MAX(CT.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type CT ON mc.company_type_id = CT.id
    GROUP BY 
        mc.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(cs.unique_companies, 0) AS unique_companies,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN rm.rank_in_year = 1 THEN 'Top Movie of the Year'
        WHEN rm.rank_in_year <= 5 THEN 'One of the Top 5 Movies'
        ELSE 'Not Ranked'
    END AS ranking_status,
    cs.company_names,
    ks.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.production_year IS NOT NULL 
    AND (rm.production_year >= 2000 AND rm.production_year <= 2023)
    AND (LOWER(rm.title) LIKE '%adventure%' OR LOWER(rm.title) LIKE '%fantasy%')
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
LIMIT 50;
