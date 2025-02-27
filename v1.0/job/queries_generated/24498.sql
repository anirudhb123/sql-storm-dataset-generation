WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        a.person_id,
        a.name,
        c.movie_id,
        r.role,
        COUNT(*) OVER (PARTITION BY a.person_id) AS movie_count,
        COALESCE(AVG(CASE WHEN t.production_year BETWEEN 2000 AND 2010 THEN t.production_year END), 0) AS avg_year_active
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    WHERE
        a.name IS NOT NULL
        AND c.nr_order IS NOT NULL
),
MoviesWithKeywords AS (
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
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
),
FinalBenchmark AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        ad.name AS actor_name,
        ad.movie_count,
        ad.avg_year_active,
        mk.keywords,
        cs.company_count,
        cs.company_names,
        CASE
            WHEN ad.avg_year_active > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS activity_status,
        COALESCE(ad.movie_count, 0) + COALESCE(cs.company_count, 0) AS total_contributions
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN
        MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        CompanyStats cs ON rm.movie_id = cs.movie_id
)
SELECT
    movie_id,
    title,
    production_year,
    actor_name,
    movie_count,
    avg_year_active,
    keywords,
    company_count,
    company_names,
    activity_status,
    total_contributions
FROM
    FinalBenchmark
WHERE
    production_year BETWEEN 1990 AND 2020
    AND total_contributions > 5
ORDER BY
    total_contributions DESC,
    production_year ASC
LIMIT 50;
