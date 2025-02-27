WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_movie_id
    FROM title m
    WHERE m.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id
    FROM movie_link ml
    JOIN title mt ON ml.linked_movie_id = mt.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY c.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.note IS NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
HighestActors AS (
    SELECT 
        mc.movie_id,
        mc.actor_name,
        mc.actor_count,
        mh.parent_movie_id
    FROM MovieCast mc
    JOIN MovieHierarchy mh ON mc.movie_id = mh.movie_id
    WHERE mc.actor_count > 5
),
TitleWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No info available') AS movie_info,
        kw.keywords
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN MovieKeywords kw ON m.id = kw.movie_id
)

SELECT 
    m.title,
    mh.parent_movie_id,
    COALESCE(ha.actor_count, 0) AS actor_count,
    COALESCE(ha.actor_name, 'N/A') AS actor_name,
    t.movie_info,
    EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year AS age_of_movie,
    CASE 
        WHEN mh.parent_movie_id IS NOT NULL THEN 'Linked'
        ELSE 'Standalone'
    END AS movie_type
FROM TitleWithInfo t
LEFT JOIN HighestActors ha ON t.movie_id = ha.movie_id
LEFT JOIN MovieHierarchy mh ON t.movie_id = mh.movie_id
WHERE t.movie_info IS NOT NULL
AND (ha.actor_count IS NULL OR ha.actor_count > 3)

ORDER BY age_of_movie DESC, actor_count DESC;
