
WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
        AND mt.title IS NOT NULL
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
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    mk.keywords,
    cd.companies,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No actors listed'
        ELSE CAST(ac.actor_count AS STRING) || ' actor(s)'
    END AS actor_info,
    CASE 
        WHEN cd.companies IS NULL THEN 'No companies associated'
        ELSE cd.companies
    END AS companies_info
FROM
    RankedMovies rm
LEFT JOIN
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE
    rm.rn = 1
    AND (rm.production_year > 1990 OR cd.companies IS NOT NULL)
ORDER BY
    rm.production_year DESC;
