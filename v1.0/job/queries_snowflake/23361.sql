WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_movies
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
),
DistinctRoles AS (
    SELECT DISTINCT
        ci.role_id
    FROM
        cast_info ci
    WHERE
        ci.person_role_id IS NOT NULL
),
FilteredActors AS (
    SELECT
        a.id AS actor_id,
        a.name,
        a.surname_pcode
    FROM
        aka_name a
    WHERE
        a.name IS NOT NULL AND a.name != ''
),
MovieDescriptions AS (
    SELECT
        m.id AS movie_id,
        COALESCE(mi.info, 'No description available') AS movie_info
    FROM
        aka_title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
),
ExtendedMovieInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        md.movie_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN
        MovieDescriptions md ON rm.movie_id = md.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year, md.movie_info
),
MaxKeywords AS (
    SELECT
        emi.production_year,
        MAX(emi.keyword_count) AS max_keywords
    FROM
        ExtendedMovieInfo emi
    GROUP BY
        emi.production_year
)
SELECT
    emi.title,
    emi.production_year,
    emi.movie_info,
    emi.keyword_count,
    CASE
        WHEN emi.keyword_count = 0 THEN 'No keywords'
        WHEN emi.keyword_count = (SELECT max_keywords FROM MaxKeywords mk WHERE mk.production_year = emi.production_year) THEN 'Most keywords for the year'
        ELSE 'Average keyword count'
    END AS keyword_analysis
FROM
    ExtendedMovieInfo emi
JOIN
    MaxKeywords mk ON emi.production_year = mk.production_year AND emi.keyword_count = mk.max_keywords
ORDER BY
    emi.production_year DESC, emi.keyword_count DESC, emi.title;

