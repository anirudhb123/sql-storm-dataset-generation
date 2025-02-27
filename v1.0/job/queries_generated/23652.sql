WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM
        aka_title t
    JOIN
        title m ON t.movie_id = m.id
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        lc.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        lt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM
        movie_link lc
    JOIN
        title lt ON lc.linked_movie_id = lt.id
    JOIN
        MovieHierarchy mh ON mh.movie_id = lc.movie_id
    WHERE
        lc.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT
    mh.movie_title,
    mh.production_year,
    COALESCE(c.n, 'Unknown') AS cast_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cm.id) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(DISTINCT k.id) DESC) AS rank_by_keywords
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name c ON ci.person_id = c.person_id AND c.name IS NOT NULL
LEFT JOIN
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mco ON mh.movie_id = mco.movie_id
LEFT JOIN
    company_name cm ON mco.company_id = cm.id
WHERE
    mh.production_year IS NOT NULL
    AND (mh.production_year > 2000 OR mh.production_year IS NULL)
GROUP BY
    mh.movie_id, mh.movie_title, mh.production_year, c.n
HAVING
    COUNT(DISTINCT ci.id) > 1
ORDER BY
    rank_by_keywords DESC,
    mh.production_year DESC
LIMIT 10 OFFSET 5;

### Explanation of the Query:
- A **CTE (Common Table Expression)** called `MovieHierarchy` builds a recursive structure of movies that are sequels to each other.
- The main **SELECT** statement retrieves movie titles and their production years, along with aggregated information about cast names, keywords, and the count of production companies.
- Uses **LEFT JOINs** to gather information from multiple tables, merging cast info and keywords related to each movie.
- **STRING_AGG** aggregates keywords into a comma-separated string, providing a compact view of associated keywords for each movie.
- It employs **COALESCE** to handle potential NULL values for cast names.
- **COUNT** and **HAVING** filters results to exclude movies with only one cast member.
- **ROW_NUMBER** is used as a window function to rank movies based on the number of distinct keywords associated with them.
- The query includes a filter on production years and limits the output to provide a sample of movies past the fifth result.
- This query illustrates advanced SQL functionalities, including recursion, window functions, and NULL handling, showcasing potential complexities in SQL semantics.
