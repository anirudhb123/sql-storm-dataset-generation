WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)
, CastDetails AS (
    SELECT
        c.movie_id,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
)
, CompanyDetails AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) OVER (PARTITION BY mc.movie_id) AS total_companies
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.actor_order,
    co.company_name,
    co.company_type,
    co.total_companies,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    COUNT(DISTINCT cd.person_id) OVER (PARTITION BY mh.movie_id) AS distinct_actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') FILTER (WHERE kw.keyword IS NOT NULL) AS keywords
FROM
    MovieHierarchy mh
LEFT JOIN
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN
    CompanyDetails co ON mh.movie_id = co.movie_id
LEFT JOIN LATERAL (
    SELECT
        mk.keyword
    FROM
        movie_keyword mk
    WHERE
        mk.movie_id = mh.movie_id
) AS kw ON true
WHERE
    co.total_companies IS NOT NULL OR cd.person_id IS NULL
ORDER BY
    mh.production_year DESC, mh.movie_id, cd.actor_order;
