WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_per_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL AND
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorDetails AS (
    SELECT
        a.person_id,
        a.name,
        c.movie_id,
        r.role,
        rk.rank_per_year,
        COALESCE(mi.info, 'N/A') AS movie_info
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        RankedMovies rk ON c.movie_id = rk.movie_id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    LEFT JOIN
        movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
),
FilteredActors AS (
    SELECT
        person_id,
        name,
        COUNT(movie_id) AS movie_count,
        STRING_AGG(DISTINCT movie_info, '; ') AS movie_infos
    FROM
        ActorDetails
    GROUP BY
        person_id, name
    HAVING
        COUNT(movie_id) > 5
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, cn.name, ct.kind
),
CombinedResults AS (
    SELECT
        fa.person_id,
        fa.name,
        fa.movie_count,
        fa.movie_infos,
        cd.company_name,
        cd.company_type
    FROM
        FilteredActors fa
    JOIN
        CompanyDetails cd ON fa.movie_count = cd.total_companies OR cd.total_companies IS NULL
)
SELECT
    person_id,
    name,
    movie_count,
    movie_infos,
    company_name,
    company_type
FROM
    CombinedResults
WHERE
    company_type IS NOT NULL
ORDER BY
    movie_count DESC, name ASC
LIMIT 50
OFFSET 10;