WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    ak.md5sum AS actor_md5,
    mh.title AS movie_title,
    mh.production_year AS release_year,
    COUNT(DISTINCT ct.kind) FILTER (WHERE ct.kind IS NOT NULL) AS total_companies,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    SUM(CASE WHEN ak.name IS NOT NULL THEN 1 ELSE 0 END) AS non_null_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id AND ak.id = ci.person_id
LEFT JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, ak.md5sum, mh.title, mh.production_year
ORDER BY 
    release_year DESC, actor_name;