WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select the top-level movies
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL 

    UNION ALL

    -- Recursive case: join with linked movies to find all related titles
    SELECT 
        lt.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link lt
    JOIN 
        aka_title t ON lt.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON lt.movie_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.level,
    COALESCE(ci.kind_id, 0) AS cast_kind_id,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    AVG(CASE WHEN pi.info_type_id = 1 THEN 1 END) AS avg_gender_female -- Assuming info_type_id 1 corresponds to gender
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id 
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = 1 -- Considering '1' as gender info type
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
GROUP BY 
    mh.title, mh.level, cast_kind_id
ORDER BY 
    mh.level, total_cast_members DESC;

-- Performance benchmark metrics can be extracted from the execution plan before and after
