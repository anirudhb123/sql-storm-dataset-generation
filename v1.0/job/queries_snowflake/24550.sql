
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, '; ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
        LISTAGG(DISTINCT cp.name, ', ') WITHIN GROUP (ORDER BY cp.name) AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cp ON mc.company_id = cp.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    rm.total_titles,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(cd.actors, 'No actors available') AS actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cp.companies, 'No companies') AS companies
FROM
    RankedMovies rm
LEFT JOIN
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    CompanyDetails cp ON rm.movie_id = cp.movie_id
WHERE
    (rm.production_year >= 2000 OR rm.production_year IS NULL) 
    AND (cd.actor_count IS NULL OR cd.actor_count > 1)
ORDER BY
    rm.production_year DESC, rm.title ASC;
