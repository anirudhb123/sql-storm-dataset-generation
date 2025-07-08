WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.id
    LEFT JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    cd.company_name,
    cd.company_type,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id AND cd.rn = 1
LEFT JOIN 
    KeywordCounts kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.rank_by_cast <= 5 
    AND rm.production_year >= 2000 
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
