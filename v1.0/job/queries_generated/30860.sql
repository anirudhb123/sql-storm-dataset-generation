WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
)

SELECT 
    a.name,
    th.title,
    th.production_year,
    COALESCE(ci.note, 'No role specified') AS role_description,
    COUNT(DISTINCT mh.movie_id) AS related_movies_count,
    COUNT(CASE WHEN mi.info IS NOT NULL THEN 1 END) AS movie_info_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title th ON th.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND th.production_year IS NOT NULL
    AND (ci.nr_order IS NULL OR ci.nr_order < 5)
GROUP BY 
    a.name, th.title, th.production_year, ci.note
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    related_movies_count DESC, a.name;

This query does the following:

1. **Recursive CTE (MovieHierarchy)**: Constructs a hierarchy starting from movies produced in or after 2000, enabling analysis of related movies.
2. **LEFT JOINs**: Combines details from multiple tables such as `aka_name`, `cast_info`, and `movie_info`, while allowing for NULL values in case of incomplete data.
3. **COALESCE**: Handles scenarios where role descriptions may be NULL, providing a default value.
4. **Aggregation Functions**: Counts the number of related movies and unique movie info data, using `COUNT` and `STRING_AGG` to compile a list of keywords.
5. **Complex WHERE Clause**: Incorporates complicated predicates, filtering different cases for NR order and ensuring names and years are present.
6. **Grouping and Having**: Groups results by actor name, title, and production year, filtering only those with more than one related movie.
7. **Ordering**: Sorts results by the count of related movies in descending order and by name.

This creates a rich insight into the actor's involvement in multiple titles while also considering their roles, production years, and associated keywords.
