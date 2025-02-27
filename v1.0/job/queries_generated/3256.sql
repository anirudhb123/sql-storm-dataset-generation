WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
), MovieCompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
), ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(mcc.company_count, 0) AS company_count,
    COALESCE(ac.actor_count, 0) AS actor_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywordCount mkc ON rm.movie_id = mkc.movie_id
LEFT JOIN 
    MovieCompanyCount mcc ON rm.movie_id = mcc.movie_id
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year, rm.title;

-- Subquery to find movies produced after the average year
SELECT 
    title,
    production_year
FROM 
    title
WHERE 
    production_year > (SELECT AVG(production_year) FROM aka_title)
INTERSECT
SELECT 
    title,
    production_year
FROM 
    title
WHERE 
    production_year BETWEEN 2000 AND 2020;
