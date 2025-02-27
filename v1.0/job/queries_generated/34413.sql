WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(c.id) AS cast_count,
    COUNT(DISTINCT(k.keyword)) AS unique_keywords,
    STRING_AGG(DISTINCT(k.keyword, ', ')) AS keywords_list,
    AVG(COALESCE(pi.info::integer, 0)) AS average_rating,
    MAX(COALESCE(pi.info, 'N/A')) AS highest_info_note,
    mh.parent_movie_id,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id 
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    mh.level <= 2
GROUP BY 
    mh.movie_id, mh.parent_movie_id, mh.level, m.title, m.production_year
ORDER BY 
    mh.parent_movie_id, mh.level DESC, average_rating DESC
LIMIT 50;

This SQL query performs the following key operations:
1. It uses a recursive common table expression (CTE) to create a hierarchy of movies based on their links to one another.
2. In the main query, it aggregates information about each movie in the hierarchy, including the count of cast members, unique keywords associated with the movie, and average ratings from the `person_info` table.
3. It includes complicated joins and uses functions like `STRING_AGG` to combine keywords into a single string.
4. The WHERE clause filters the results to include only a specific level of the hierarchy and limits the output for performance benchmarking.
5. The query groups the results and orders them based on parent movie ID and rating.
