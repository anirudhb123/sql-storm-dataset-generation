WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_by_title,
        COUNT(DISTINCT t.keyword) OVER (PARTITION BY m.id) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword t ON mk.keyword_id = t.id
    WHERE
        m.production_year IS NOT NULL
),
ValidActors AS (
    SELECT
        ca.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ca.role_id) AS role_count
    FROM
        cast_info ca
    INNER JOIN
        aka_name a ON ca.person_id = a.person_id
    WHERE
        ca.note IS NULL
    GROUP BY
        ca.movie_id, a.name
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mc.note IS NULL
),
ExternalLinks AS (
    SELECT
        ml.movie_id,
        COUNT(DISTINCT ml.linked_movie_id) AS linked_count
    FROM
        movie_link ml
    GROUP BY
        ml.movie_id
),
FinalOutput AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        va.actor_name,
        va.role_count,
        COALESCE(mc.company_name, 'Independent') AS company_name,
        COALESCE(mc.company_type, 'N/A') AS company_type,
        el.linked_count,
        rm.keyword_count,
        CASE
            WHEN rm.rank_by_title = 1 THEN 'First in the Year'
            WHEN rm.rank_by_title < 4 THEN 'Top 3 in the Year'
            ELSE 'Others'
        END AS movie_rank_category
    FROM
        RankedMovies rm
    LEFT JOIN
        ValidActors va ON rm.movie_id = va.movie_id
    LEFT JOIN
        MovieCompanies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN
        ExternalLinks el ON rm.movie_id = el.movie_id
)
SELECT
    *
FROM
    FinalOutput
WHERE
    (linked_count > 5 OR keyword_count > 3)
    AND (movie_rank_category = 'Top 3 in the Year' OR company_type != 'N/A')
ORDER BY
    production_year DESC, title;
