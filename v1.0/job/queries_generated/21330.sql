WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
),
DetailedCast AS (
    SELECT
        c.id AS cast_id,
        c.movie_id,
        coalesce(p.name, cn.name) AS actor_name,
        rt.role,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS order_rank
    FROM
        cast_info c
    LEFT JOIN
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN
        char_name cn ON p.id IS NULL AND c.person_id = cn.imdb_id
    LEFT JOIN
        role_type rt ON c.role_id = rt.id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type,
        COALESCE(mc.note, 'No Notes') AS notes
    FROM
        movie_companies mc
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
),
TopMoviesWithDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        dc.actor_name,
        dc.role,
        dc.nr_order,
        dc.order_rank,
        mc.company_name,
        mc.company_type,
        mc.notes
    FROM
        RankedMovies rm
    LEFT JOIN
        DetailedCast dc ON rm.movie_id = dc.movie_id
    LEFT JOIN
        MovieCompanies mc ON rm.movie_id = mc.movie_id
),
FinalBenchmark AS (
    SELECT
        t.movie_id,
        MAX(t.title) AS max_title,
        COUNT(DISTINCT t.actor_name) AS unique_actors,
        STRING_AGG(DISTINCT t.company_name, ', ') AS companies,
        SUM(CASE WHEN t.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count
    FROM
        TopMoviesWithDetails t
    GROUP BY
        t.movie_id
)
SELECT
    fb.movie_id,
    fb.max_title,
    fb.unique_actors,
    fb.companies,
    fb.pre_2000_count,
    CASE 
        WHEN fb.unique_actors > 5 THEN 'Ensemble Cast'
        WHEN fb.pre_2000_count > 0 THEN 'Classic Films'
        ELSE 'Modern Films'
    END AS film_category
FROM
    FinalBenchmark fb
WHERE
    fb.unique_actors IS NOT NULL OR fb.companies IS NOT NULL
ORDER BY
    fb.movie_id;
