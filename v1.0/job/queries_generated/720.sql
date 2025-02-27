WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY 
        c.movie_id
),
KeywordAggregation AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(ac.actor_count, 0) AS actor_count,
    ka.keywords
FROM
    RankedMovies rm
LEFT JOIN 
    CompanyCount cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    KeywordAggregation ka ON rm.movie_id = ka.movie_id
WHERE
    (rm.production_year >= 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
