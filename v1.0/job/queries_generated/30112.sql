WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        1 AS level,
        ARRAY[id] AS path
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL -- Root movies that are not episodes

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        path || t.id
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(CAST(STRING_AGG(DISTINCT c.name, ', ') AS text), 'No Cast') AS cast_members,
    COALESCE(CAST(STRING_AGG(DISTINCT k.keyword, ', ') AS text), 'No Keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN c.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
    AVG(CASE WHEN pc.info_type_id = 1 THEN LENGTH(pc.info) END) AS avg_person_info_length
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    person_info pc ON c.person_id = pc.person_id AND pc.info_type_id = 1 
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 -- Only including movies with associated companies
ORDER BY 
    m.production_year DESC, m.title;

-- This query constructs a hierarchy of movies, incorporates various subqueries for cast and keywords, 
-- counts companies associated with these movies, and computes average info length 
-- from person information, offering a comprehensive view suitable for performance benchmarking.
