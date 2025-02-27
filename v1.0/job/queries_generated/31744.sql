WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select movie_id and title for all movies with their direct cast
    SELECT
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000
    
    UNION ALL
    
    -- Recursive case: join to find sequels or related movies recursively
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        at.production_year > 2000
),
CastDetails AS (
    -- Get persons and their roles in movies
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
MovieInfo AS (
    -- Aggregate movie info including the count of unique keywords and average production year
    SELECT
        at.id AS movie_id,
        at.title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN at.production_year IS NOT NULL THEN at.production_year ELSE NULL END) AS avg_production_year
    FROM
        aka_title at
    LEFT JOIN
        movie_keyword mk ON at.id = mk.movie_id
    GROUP BY
        at.id, at.title
)
SELECT
    mh.movie_id,
    mh.title,
    cd.actor_name,
    cd.role,
    cd.role_order,
    mi.keyword_count,
    mi.avg_production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM
    MovieHierarchy mh
LEFT JOIN
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE
    cd.role_order IS NOT NULL OR cd.actor_name IS NOT NULL -- Filter to keep movies with either cast info or title
GROUP BY
    mh.movie_id, mh.title, cd.actor_name, cd.role, cd.role_order, mi.keyword_count, mi.avg_production_year
ORDER BY
    mh.title, cd.role_order
;
