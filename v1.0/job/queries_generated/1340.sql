WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT co.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    COALESCE(cc.company_count, 0) AS company_count,
    rm.cast_count,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCount cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.cast_count > 0 
    AND rm.rn <= 100
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
