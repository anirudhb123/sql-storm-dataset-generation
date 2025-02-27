WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m_link.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m_link
    JOIN 
        title t ON m_link.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON m_link.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COALESCE(mh.level, 0) AS movie_level,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS role_notes
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year >= 2000
    AND (mh.level IS NULL OR mh.level <= 2)
GROUP BY 
    a.name, m.title, mh.level
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    keyword_count DESC, actor_name, movie_title;

In this query:

1. A recursive CTE `movie_hierarchy` is defined to build a hierarchy of movies based on linked movies. This helps gather information about linked movies up to a depth of two levels.
2. We then query for actors, their movies, and the number of keywords associated with those movies while applying filtering conditions on production years and hierarchy levels.
3. We use `LEFT JOIN` to ensure we don't miss movies without keywords, and `COALESCE` to handle potential null levels.
4. We aggregate role notes and count distinct keywords for additional insights into the movie's context.
5. The `HAVING` clause filters the results to only include actors who have played more than one role across various movies.
6. The results are ordered primarily by keyword count and then by actor and movie titles, providing a clear and organized output for performance benchmarking analysis.
