
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
),
ActorRoleCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_actors,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_roles
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
MovieKeywordSummary AS (
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
MovieInfoStats AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_types_count,
        MAX(LENGTH(mi.info)) AS max_info_length
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    rm.total_titles,
    ar.distinct_actors,
    ar.ordered_roles,
    mk.keywords,
    mis.info_types_count,
    mis.max_info_length
FROM
    RankedMovies rm
LEFT JOIN
    ActorRoleCounts ar ON rm.movie_id = ar.movie_id
LEFT JOIN
    MovieKeywordSummary mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    MovieInfoStats mis ON rm.movie_id = mis.movie_id
WHERE
    (ar.distinct_actors IS NULL OR ar.ordered_roles > 3)
    AND (rm.production_year BETWEEN 2000 AND 2023)  
ORDER BY
    rm.production_year DESC,
    rm.title_rank ASC
LIMIT 100;
