WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL AND mt.kind_id IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year, 
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

movie_cast AS (
    SELECT 
        mc.movie_id,
        COUNT(cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info mc
    JOIN 
        aka_name an ON mc.person_id = an.person_id
    GROUP BY 
        mc.movie_id
),

movie_info_details AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Synopsis' THEN mi.info END) AS synopsis,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(mci.total_cast, 0) AS total_cast,
    COALESCE(mci.cast_names, 'No Cast') AS cast_names,
    COALESCE(mids.synopsis, 'No Synopsis') AS synopsis,
    NULLIF(mids.rating::numeric, 0) AS rating
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mci ON mh.movie_id = mci.movie_id
LEFT JOIN 
    movie_info_details mids ON mh.movie_id = mids.movie_id
WHERE 
    mh.production_year > 2000
    AND (mci.total_cast > 5 OR mids.rating IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    mh.title COLLATE "C" ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

UNION

SELECT 
    NULL AS movie_id,
    NULL AS title,
    NULL AS production_year,
    NULL AS kind_id,
    0 AS total_cast,
    'No Cast' AS cast_names,
    'No Synopsis' AS synopsis,
    NULL AS rating
WHERE NOT EXISTS (SELECT 1 FROM movie_cast);
