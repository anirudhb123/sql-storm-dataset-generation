WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    pk.keyword,
    ci.company_name,
    ci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularKeywords pk ON rm.production_year = pk.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.production_year = ci.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC, pk.keyword_count DESC
LIMIT 50;
