WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastWithDetails AS (
    SELECT
        ca.person_id,
        ca.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ak.name) AS actor_order
    FROM
        cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
),
MovieKeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT co.kind, ', ') AS company_kinds
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type co ON mc.company_type_id = co.id
    GROUP BY
        mc.movie_id
)
SELECT
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    cd.actor_order,
    cd.actor_name,
    kw.keyword_count,
    ci.total_companies,
    ci.company_kinds
FROM
    MovieHierarchy mh
LEFT JOIN CastWithDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN MovieKeywordCounts kw ON mh.movie_id = kw.movie_id
LEFT JOIN CompanyInfo ci ON mh.movie_id = ci.movie_id
WHERE
    mh.level < 3 -- Limit to first two levels of episodes
    AND (ci.total_companies IS NULL OR ci.total_companies > 1) -- Include movies with no companies or more than 1
ORDER BY
    mh.production_year DESC,
    mh.movie_title,
    cd.actor_order;
This SQL query performs various tasks:

1. **Recursive CTE**: Creates a hierarchy of movies and episodes produced after 2000.
2. **Casting Details**: Aggregates actor names per movie, applying a window function to order actors.
3. **Keyword Counts**: Counts distinct keywords associated with each movie.
4. **Company Information**: Groups movies with their related production companies and company types.
5. **Final Selection**: Combines information while enforcing logical constraints on the movie levels and company counts to filter results effectively.
