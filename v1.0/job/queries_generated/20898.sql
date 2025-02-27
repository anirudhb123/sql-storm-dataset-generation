WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS depth,
        ARRAY[mt.title] AS title_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.depth + 1,
        mh.title_path || m.title
    FROM 
        movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5
),
cast_summary AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
movie_info_summary AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        COALESCE(mi.info, 'No Info') AS movie_info,
        COALESCE(ki.keyword, 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mi.info_type_id) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        mi.note IS NULL OR mi.note != 'Excluded'
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.depth,
    cs.cast_count,
    cs.actors,
    mis.movie_info,
    mis.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id AND mis.rn = 1
WHERE 
    mh.depth = 1 
    OR (mh.depth > 1 AND cs.cast_count > 3)
ORDER BY 
    mh.depth, 
    mh.title;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **`movie_hierarchy` CTE**: This recursive CTE builds a hierarchy of movies linked to each other through the `movie_link` table, restricted to movies produced after 2000 and limited to a depth of 5.
   - **`cast_summary` CTE**: Summarizes cast information by counting distinct actors for each movie and aggregating their names into a comma-separated string.
   - **`movie_info_summary` CTE**: Gathers information and keywords for each movie, providing default strings if no information is available, while also using window functions to rank rows.

2. **Joins and NULL Logic**:
   - The final query performs left joins, allowing for movies without associated casts or information to be included in the result.
   - It filters results based on the movie's depth in the hierarchy and the number of cast members for deeper movies.

3. **Advanced SQL Features**:
   - Aggregation functions like `COUNT` and `STRING_AGG`.
   - A window function (`ROW_NUMBER()`) is used to limit to the first information entry for each movie.
   - Conditions in WHERE clauses exhibit compound logic, taking into account depth and other constraints.

4. **Use of Ordered Results**: The `ORDER BY` clause organizes the output by depth and movie title, adding clarity to the report's structure. 

This query showcases intricate SQL capabilities, focusing on performance benchmarking through complex relationships and filters within the hypothetical movie database.
