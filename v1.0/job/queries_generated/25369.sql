WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
Casts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Production'
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        COALESCE(c.cast_count, 0) AS cast_count,
        COALESCE(comp.company_count, 0) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        Casts c ON rm.movie_id = c.movie_id
    LEFT JOIN 
        MovieCompanies comp ON rm.movie_id = comp.movie_id
)
SELECT 
    title,
    production_year,
    STRING_AGG(keyword, ', ') AS keywords,
    cast_count,
    company_count
FROM 
    FinalResults
GROUP BY 
    movie_id, title, production_year, cast_count, company_count
ORDER BY 
    production_year DESC, cast_count DESC, company_count DESC;
