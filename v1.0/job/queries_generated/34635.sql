WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        1 AS depth
    FROM
        aka_title t
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.linked_movie_id AS movie_id,
        lt.title,
        mh.depth + 1
    FROM
        movie_link m
    JOIN
        title lt ON m.linked_movie_id = lt.id
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)

SELECT
    p.name AS person_name,
    t.title AS movie_title,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(mh.depth) AS average_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM
    aka_name p
JOIN
    cast_info c ON p.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE
    p.md5sum IS NOT NULL -- Exclude entries where MD5 sum is NULL
    AND c.nr_order IS NOT NULL -- Ensure role ordering is known
GROUP BY
    p.name, t.title
HAVING
    COUNT(DISTINCT c.movie_id) > 5 -- Only include people with more than 5 movies
ORDER BY
    total_movies DESC,
    average_depth ASC
LIMIT 100;

**Explanation:**
- A recursive CTE (`MovieHierarchy`) is used to build a hierarchy of movies and their linked relationships.
- The main query performs a series of joins to connect actors to their movies and gather statistics such as the total count of movies they've been in and the average depth of linked movies.
- It uses `STRING_AGG` to collect keywords associated with titles and employs `HAVING` to filter for actors with more than 5 movies.
- `LEFT JOIN` is used to ensure that even if there are no keywords or links, the actor's information remains present in the results.
- The query includes logic to exclude NULL MD5 sums and ensures the order of roles is considered.
