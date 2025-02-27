WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select all movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::INTEGER AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    -- Recursive case: Find linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    ak.name AS actor_name,
    cc.kind AS cast_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS summary_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(ck.name, '') AS character_name
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    comp_cast_type cc ON ci.role_id = cc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    complete_cast cc2 ON mh.movie_id = cc2.movie_id
LEFT JOIN 
    char_name ck ON cc2.subject_id = ck.imdb_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    (mh.level <= 3 OR ak.name IS NOT NULL)
    AND (mh.production_year > 2000 OR cc.kind IS NOT NULL)
    AND (k.keyword IS NOT NULL OR md5sum IS NOT NULL)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, ak.name, cc.kind, ck.name
ORDER BY 
    mh.production_year DESC, mh.level, ak.name;
