WITH RECURSIVE MovieHierarchy AS (
    
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL

    UNION ALL

    
    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM title e
    JOIN MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),

RankedCast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(RC.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE
        WHEN mh.level = 1 THEN 'Root Movie'
        ELSE 'Episode'
    END AS movie_type
FROM MovieHierarchy mh
LEFT JOIN (
    SELECT
        movie_id,
        COUNT(*) AS actor_count
    FROM RankedCast
    GROUP BY movie_id
) RC ON mh.movie_id = RC.movie_id
LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY mh.production_year DESC, mh.movie_id;