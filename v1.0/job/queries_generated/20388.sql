WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth,
        NULL AS parent_movie_id
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.depth + 1,
        mh.movie_id AS parent_movie_id
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    mv.movie_id,
    mv.movie_title,
    mh.parent_movie_id,
    COALESCE(CG.name, 'Unknown Company') AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END) AS not_assigned_roles,
    ARRAY_AGG(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
    MAX(CASE 
            WHEN mi.info_type_id IS NOT NULL THEN mi.info 
            ELSE 'No Information' END) AS movie_info,
    ROW_NUMBER() OVER(PARTITION BY mv.movie_id ORDER BY mv.movie_title) AS rank
FROM 
    MovieHierarchy mv
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
LEFT JOIN 
    company_name CG ON mc.company_id = CG.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    complete_cast co ON mv.movie_id = co.movie_id
LEFT JOIN 
    cast_info ci ON co.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mv.movie_id = mi.movie_id
WHERE 
    mv.depth < 3 
    AND (ct.kind IS NOT NULL OR CG.name IS NOT NULL)
GROUP BY 
    mv.movie_id, mv.movie_title, mh.parent_movie_id, CG.name, ct.kind
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    mv.movie_title ASC, total_actors DESC;

### Explanation:
- **Common Table Expressions (CTEs)**: A recursive CTE `MovieHierarchy` is created to explore the movie links and build a hierarchy of movies, retrieving linked movies to a depth of 2.
- **LEFT JOIN**: The query makes extensive use of `LEFT JOIN`s to aggregate information from various related tables, ensuring that even if some of the joined data is missing, the main `MovieHierarchy` information is retained.
- **AGGREGATIONS**: `COUNT`, `SUM`, and `ARRAY_AGG` functions to retrieve total actors, count those with no roles assigned, and list unique keywords.
- **NULL Logic**: The query handles NULL values using `COALESCE` to provide default strings when certain values are absent and employs a `CASE` statement to offer a fallback information string when no info is available.
- **PARTITIONING and Ranking**: The `ROW_NUMBER()` window function is used to assign a ranking based on the movie title within each movie grouping.
- **COMPLEX HAVING Clause**: This ensures that only movies with more than 3 distinct actors will be included. 

The query is designed to benchmark how well the database handles complex queries involving multiple joins, aggregations, and recursive structures while managing various SQL semantics gracefully.
