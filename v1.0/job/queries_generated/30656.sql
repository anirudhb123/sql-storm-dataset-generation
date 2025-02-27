WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        mt.production_year,
        mt.kind_id,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt 
    WHERE 
        mt.episode_of_id IS NULL -- Start with movies that aren't episodes

    UNION ALL

    SELECT 
        et.id,
        et.title,
        mh.level + 1,
        et.production_year,
        et.kind_id,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id -- Recursive join for episodes
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(GROUP_CONCAT(DISTINCT ct.kind), 'No companies associated') AS company_types,
    COUNT(DISTINCT km.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title) AS row_num
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ca ON ca.movie_id = mh.movie_id 
LEFT JOIN 
    aka_name ak ON ak.person_id = ca.person_id 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id 
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id 
LEFT JOIN 
    keyword km ON km.id = mk.keyword_id 
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id 
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 0 
ORDER BY 
    mh.production_year DESC, mh.movie_title;
