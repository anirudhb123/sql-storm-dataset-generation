WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mt.episode_of_id
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieCast AS (
    SELECT
        c.movie_id,
        c.person_id,
        r.role,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
),
MovieKeywordDetails AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_type_id) AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.companies, 'No Companies') AS companies,
    MAX(ma.person_id) AS last_actor,
    COUNT(DISTINCT ma.person_id) AS total_actors
FROM MovieHierarchy mh
LEFT JOIN MovieKeywordDetails mk ON mh.movie_id = mk.movie_id
LEFT JOIN CompanyDetails mc ON mh.movie_id = mc.movie_id
LEFT JOIN MovieCast ma ON mh.movie_id = ma.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY
    mh.production_year DESC, mh.title ASC
LIMIT 50;
