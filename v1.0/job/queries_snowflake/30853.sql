
WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS depth
    FROM aka_title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT mv.id, mv.title, mh.depth + 1
    FROM aka_title mv
    JOIN movie_link ml ON mv.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.depth < 3
),
ActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COALESCE(MAX(ci.nr_order), 0) AS highest_cast_order,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN complete_cast cc ON ci.movie_id = cc.movie_id
    LEFT JOIN movie_companies mc ON cc.movie_id = mc.movie_id
    GROUP BY a.id, a.name
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
SelectedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.depth,
        ak.actor_name,
        ak.highest_cast_order,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords
    FROM MovieHierarchy mh
    LEFT JOIN ActorDetails ak ON mh.movie_id = ak.actor_id
    LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
    WHERE mh.depth = 2
)
SELECT
    sm.title,
    sm.keywords,
    sm.highest_cast_order,
    CASE 
        WHEN sm.highest_cast_order = 0 THEN 'No Roles'
        WHEN sm.highest_cast_order > 5 THEN 'Prolific Actor'
        ELSE 'Occasional Actor'
    END AS actor_type
FROM SelectedMovies sm
ORDER BY sm.highest_cast_order DESC, sm.title ASC
LIMIT 50;
