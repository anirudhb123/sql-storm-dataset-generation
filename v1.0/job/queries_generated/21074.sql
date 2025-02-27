WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieCompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MIN(ct.kind) AS main_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    mcd.company_names,
    mcd.main_company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieCompanyData mcd ON rm.movie_id = mcd.movie_id
WHERE 
    rm.rank_within_year = 1
    AND (mcd.company_names IS NOT NULL 
         OR (mcd.company_names IS NULL AND rm.production_year < 2000))
ORDER BY 
    rm.production_year DESC, rm.title;

-- Extra generation checking on edge cases and performance.
WITH DistinctMovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    CASE 
        WHEN dmk.unique_keywords > 5 THEN 'Interest-Packed'
        ELSE 'Average'
    END AS Keyword_Interest_Level,
    rm.production_year
FROM 
    RankedMovies rm
LEFT JOIN 
    DistinctMovieKeywords dmk ON rm.movie_id = dmk.movie_id
WHERE 
    (rm.production_year BETWEEN 2000 AND 2020)
    OR (rm.production_year < 1980 AND dmk.unique_keywords IS NULL)
ORDER BY 
    rm.production_year ASC, rm.title;
