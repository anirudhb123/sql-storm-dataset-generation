WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    INNER JOIN title t ON m.movie_id = t.id
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id 
    WHERE
        mh.level < 5  -- Limit the recursion depth
),
CastWithRole AS (
    SELECT
        ak.name AS actor_name,
        mt.title,
        mt.production_year,
        ci.nr_order,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title mt ON ci.movie_id = mt.movie_id
    JOIN role_type rt ON ci.role_id = rt.id
    WHERE
        mt.production_year BETWEEN 2010 AND 2020
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompanyProduction AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM
        movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
)
SELECT
    mh.title,
    mh.production_year,
    cw.actor_name,
    cw.role,
    mk.keywords,
    cp.company_count,
    COUNT(DISTINCT cw.actor_name) OVER (PARTITION BY mh.movie_id) AS total_actors,
    CASE 
        WHEN cp.company_count > 1 THEN 'Multiple Companies'
        ELSE 'Single Company'
    END AS company_status
FROM
    MovieHierarchy mh
LEFT JOIN CastWithRole cw ON mh.movie_id = cw.movie_id
LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN CompanyProduction cp ON mh.movie_id = cp.movie_id
WHERE
    (mh.production_year IS NOT NULL AND mh.production_year > 2000)
    OR (mk.keywords IS NOT NULL)
ORDER BY
    mh.production_year DESC, mh.level, cw.actor_rank
LIMIT 100;
