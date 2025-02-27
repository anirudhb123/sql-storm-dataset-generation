WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS role_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
MovieKeywords AS (
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
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mk.keyword_count,
        rm.role_count_rank
    FROM 
        RankedMovies rm
    JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.role_count_rank <= 5
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword_count,
    COALESCE(NULLIF(tm.production_year, 2023), 'Not Released This Year') AS year_status
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;

-- Including NULL logic and complicated predicates
WITH FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.name IS NOT NULL
        AND (ct.kind IS NULL OR ct.kind NOT IN ('Distributor'))
),
CompanyMovieCounts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT company_name) AS company_count
    FROM 
        FilteredCompanies
    GROUP BY 
        movie_id
)

SELECT 
    t.title,
    t.production_year,
    COALESCE(cmc.company_count, 0) AS company_movie_count
FROM 
    aka_title t
LEFT JOIN 
    CompanyMovieCounts cmc ON t.id = cmc.movie_id
WHERE 
    t.production_year < 2020
ORDER BY 
    cmc.company_movie_count DESC;
