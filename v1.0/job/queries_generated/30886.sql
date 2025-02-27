WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

MovieCasting AS (
    SELECT 
        ac.movie_id,
        COUNT(DISTINCT ac.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(CASE WHEN ak.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
        MAX(CASE WHEN ak.gender = 'M' THEN 1 ELSE 0 END) AS male_cast
    FROM 
        cast_info ac
    JOIN 
        aka_name ak ON ac.person_id = ak.person_id
    GROUP BY 
        ac.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mc.cast_count,
        mc.actors,
        mc.female_cast,
        mc.male_cast
    FROM 
        aka_title m
    LEFT JOIN 
        MovieCasting mc ON m.id = mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mi.cast_count,
    mi.actors,
    mi.female_cast,
    mi.male_cast,
    COUNT(DISTINCT cm.company_id) AS production_companies
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies cm ON mh.movie_id = cm.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mi.cast_count, mi.actors, mi.female_cast, mi.male_cast
ORDER BY 
    mh.production_year DESC, mh.title ASC;

