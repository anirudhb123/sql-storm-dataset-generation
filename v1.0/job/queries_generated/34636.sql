WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           1 AS depth
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, 
           mh.depth + 1
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

CastDetails AS (
    SELECT ci.movie_id, 
           ak.name AS actor_name, 
           ci.nr_order, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order,
           COALESCE(NULLIF(ak.md5sum, ''), 'No MD5') AS actor_md5sum
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),

MovieKeywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(kw.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
),

InfoSummary AS (
    SELECT mi.movie_id, 
           STRING_AGG(CONCAT(it.info, ': ', mi.info), '; ') AS info_details
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)

SELECT mh.movie_id, 
       mh.title, 
       mh.production_year, 
       CD.actor_name,
       CD.actor_md5sum,
       CD.actor_order,
       MK.keywords,
       IS.info_details
FROM MovieHierarchy mh
LEFT JOIN CastDetails CD ON mh.movie_id = CD.movie_id
LEFT JOIN MovieKeywords MK ON mh.movie_id = MK.movie_id
LEFT JOIN InfoSummary IS ON mh.movie_id = IS.movie_id
WHERE mh.depth <= 2
ORDER BY mh.production_year DESC, mh.title;
