WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        'Origin' AS relation
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        'Linked' AS relation
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        ml.movie_id IN (SELECT movie_id FROM movie_hierarchy)
)

, cast_info_details AS (
    SELECT 
        ci.movie_id,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS total_roles,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)

, keyword_aggregates AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COALESCE(c.id, 0) AS cast_info_id,
    c.total_roles,
    c.total_actors,
    COALESCE(ka.keywords, 'No Keywords') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info_details c ON mh.movie_id = c.movie_id
LEFT JOIN 
    keyword_aggregates ka ON mh.movie_id = ka.movie_id
WHERE 
    mh.relation = 'Linked' OR mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC,
    mh.movie_title COLLATE "C" ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

This SQL query showcases several advanced features, including:
1. A recursive CTE (`movie_hierarchy`) to traverse and build a hierarchy of movies based on their links.
2. Aggregation with `COUNT` to determine the total roles and actors involved per movie in `cast_info_details`.
3. A `STRING_AGG` to combine keywords associated with each movie in `keyword_aggregates`.
4. Use of `COALESCE` to handle NULL values when no data is found in joins.
5. Filtering on production years and relationships with an `OR` clause, highlighting potential edge cases.
6. Ordering results alphabetically and numerically while limiting the number of rows returned for performance benchmarking. 

