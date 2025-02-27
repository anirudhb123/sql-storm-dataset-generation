WITH RECURSIVE MovieHierarchy AS (
    -- CTE to recursively get all movies and their linked counterparts
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS depth
    FROM title m
    WHERE m.production_year >= 2000 -- starting point for recent movies

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        mh.depth + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
),
RecentMovies AS (
    -- Getting all recent movies produced after 2000
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        title.kind_id
    FROM title
    WHERE production_year > 2010
),
ActorCount AS (
    -- Getting the number of actors per movie
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
IndependentMovies AS (
    -- Identifying independent movies
    SELECT 
        m.id AS movie_id,
        m.title
    FROM title m
    JOIN movie_companies mc ON mc.movie_id = m.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'Independent'
),
KeywordCount AS (
    -- Counting unique keywords per movie
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
FinalResults AS (
    -- Joining all previous CTEs and applying qualifications
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN im.movie_id IS NOT NULL THEN 'Independent'
            ELSE 'Not Independent'
        END AS movie_type,
        mh.depth
    FROM RecentMovies rm
    LEFT JOIN ActorCount ac ON rm.movie_id = ac.movie_id
    LEFT JOIN KeywordCount kc ON rm.movie_id = kc.movie_id
    LEFT JOIN IndependentMovies im ON rm.movie_id = im.movie_id
    LEFT JOIN MovieHierarchy mh ON rm.movie_id = mh.movie_id
)
SELECT 
    *,
    RANK() OVER (PARTITION BY movie_type ORDER BY actor_count DESC, production_year DESC) AS rank_within_type
FROM FinalResults
WHERE depth <= 3
ORDER BY movie_type, actor_count DESC, production_year DESC
LIMIT 100; 
