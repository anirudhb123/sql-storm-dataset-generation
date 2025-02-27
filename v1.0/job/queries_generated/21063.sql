WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level,
        mt.id::text AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1,
        mh.path || '->' || m.id::text
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.level,
    CASE 
        WHEN h.level = 0 THEN 'Original'
        WHEN h.level > 0 THEN 'Sequel'
        ELSE 'Unknown'
    END AS movie_type,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
    SUM(CASE 
        WHEN mt.info LIKE '%Oscar%' THEN 1 
        ELSE 0 
    END) AS oscar_count
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_info mt ON h.movie_id = mt.movie_id
WHERE 
    h.production_year >= 2000
GROUP BY 
    h.movie_id, h.title, h.production_year, h.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    h.production_year DESC, h.movie_id;

### Query Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE `movie_hierarchy` constructs a hierarchy of movies including links (like sequels or series).
2. **Outer Joins**: LEFT JOINs are used to include movies even if they have no cast or title information.
3. **Aggregations**: Uses `COUNT`, `SUM`, and `STRING_AGG` to calculate the number of unique cast members, total Oscar nominations, and a concatenated list of casts respectively.
4. **Conditional Logic**: The `CASE` statement classifies movies into 'Original' or 'Sequel' based on their hierarchy levels.
5. **Complex Conditions**: The WHERE clause filters the results to include only movies produced after the year 2000.
6. **GROUP BY and HAVING**: Groups results by movie attributes and ensures only movies with more than one cast member are shown.
7. **Ordering**: Orders the final output by production year (descending) and movie ID.

This query captures intricate relationships in the movie database while showcasing various SQL constructs and corner cases.
