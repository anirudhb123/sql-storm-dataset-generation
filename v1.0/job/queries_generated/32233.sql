WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000 -- Filter for movies released after 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        COALESCE(ka.name, '<Unknown>') AS actor_display_name
    FROM cast_info ci
    LEFT JOIN aka_name ka ON ci.person_id = ka.person_id
),
MoviesWithKeywords AS (
    SELECT 
        mt.title,
        mt.production_year,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
),
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    cd.actor_display_name,
    cd.actor_rank,
    mwk.keywords,
    COALESCE(mcc.company_count, 0) AS company_count
FROM MovieHierarchy mh
LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN MoviesWithKeywords mwk ON mh.movie_id = mwk.movie_id
LEFT JOIN MovieCompanyCounts mcc ON mh.movie_id = mcc.movie_id
WHERE 
    (cd.actor_rank < 5 OR cd.actor_rank IS NULL) -- Only get top 4 actors or movies with no cast
    AND (mwk.keywords IS NOT NULL)
ORDER BY mh.production_year DESC, mh.title, cd.actor_rank;
