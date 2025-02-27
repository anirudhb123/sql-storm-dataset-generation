WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        c.movie_id,
        ak.name AS actor_name,
        rp.role AS role_name
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    JOIN
        role_type rp ON c.role_id = rp.id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
KeywordDetails AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
MovieStats AS (
    SELECT
        rm.movie_id,
        COALESCE(SUM(mi.info_type_id), 0) AS info_count,
        COUNT(DISTINCT ad.actor_name) AS actor_count,
        STRING_AGG(DISTINCT kd.keyword, ', ') AS keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN
        ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN
        KeywordDetails kd ON rm.movie_id = kd.movie_id
    GROUP BY
        rm.movie_id
)

SELECT
    ms.movie_id,
    ms.info_count,
    ms.actor_count,
    ms.keywords,
    cd.company_name,
    cd.company_type,
    CASE
        WHEN ms.info_count > 5 THEN 'Well-documented'
        WHEN ms.info_count IS NULL THEN 'No info available'
        ELSE 'Moderately documented'
    END AS documentation_status,
    COUNT(DISTINCT CASE WHEN ad.actor_name IS NOT NULL THEN ad.actor_name END) OVER (PARTITION BY ms.movie_id) AS unique_actors_count
FROM
    MovieStats ms
LEFT JOIN
    CompanyDetails cd ON ms.movie_id = cd.movie_id
LEFT JOIN
    ActorDetails ad ON ms.movie_id = ad.movie_id
WHERE
    ms.actor_count > 0
ORDER BY
    ms.movie_id, cd.company_name;
