WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select all movies as the first level
    SELECT 
        m.id AS movie_id,
        t.title,
        0 AS level,
        NULL AS parent_movie_id
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        cc.subject_id = ci.person_id

    UNION ALL

    -- Recursive case: Find sequels or related movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.level,
    COALESCE(NULLIF(cn.name, ''), 'Unknown') AS company_name,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY h.movie_id ORDER BY h.level DESC) AS rank_level,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) OVER(PARTITION BY h.movie_id) AS female_actors_count,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    movie_hierarchy h
LEFT JOIN 
    movie_companies mc ON mc.movie_id = h.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = h.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    name p ON ci.person_id = p.imdb_id 
WHERE 
    h.level <= 2 AND (m.production_year IS NULL OR m.production_year >= 2000)
GROUP BY 
    h.movie_id, h.title, h.level, cn.name, m.production_year
ORDER BY 
    h.level, total_cast DESC, h.title;
