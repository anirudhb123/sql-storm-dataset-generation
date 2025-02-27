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
),
MovieWithKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
ActorInformation AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        a.name IS NOT NULL 
        AND ci.nr_order IS NOT NULL
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    mwk.keywords,
    ai.actor_name,
    ai.actor_rank,
    cd.companies,
    cd.company_types
FROM
    RankedMovies rm
LEFT JOIN
    MovieWithKeywords mwk ON rm.movie_id = mwk.movie_id
LEFT JOIN
    ActorInformation ai ON rm.movie_id = ai.movie_id
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE
    (ai.actor_rank IS NULL OR ai.actor_rank <= 3) -- Top 3 actors or no actors
    AND (cd.companies IS NOT NULL OR cd.company_types IS NULL) -- Companies exist or no company types
ORDER BY
    rm.production_year DESC,
    rm.title ASC
FETCH FIRST 100 ROWS ONLY;
