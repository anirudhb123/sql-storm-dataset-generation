WITH RECURSIVE movie_hierarchy AS (
    -- Anchor member: Get all root movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(cast_info.nr_order, 0) AS cast_order,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        (SELECT movie_id, MIN(nr_order) AS nr_order 
         FROM cast_info 
         GROUP BY movie_id) cast_info ON mt.id = cast_info.movie_id
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    -- Recursive member: Get children movies
    SELECT 
        ml.linked_movie_id,
        at.title,
        COALESCE(ci.nr_order, 0) AS cast_order,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    LEFT JOIN 
        cast_info ci ON ml.linked_movie_id = ci.movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_cast_names,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.level
ORDER BY 
    mh.level, num_cast_members DESC;

-- Additionally, filter for high-profile movies that have more than 3 distinct cast members 
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
    AND mh.level = 1;

This SQL query demonstrates multiple advanced SQL concepts including:

- **Recursive CTE** (`movie_hierarchy`) to build a hierarchy of movies linked via `movie_link`.
- **Left Joins** to connect `aka_title`, `cast_info`, and `aka_name`, allowing for the extraction of cast details.
- **Aggregations** with `COUNT()` and `STRING_AGG()` to gather insights on cast members and their names.
- **Conditional Aggregation** using a `CASE` statement to count notes associated with cast members.
- **Ordering** and filtering logic at the end to isolate high-profile movies based on criteria from the previous steps.

This provides a rich performance benchmark for a complex search involving linked movie data, cast information, and conditions.
