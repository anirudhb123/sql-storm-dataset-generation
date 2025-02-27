WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ci.nr_order, 0) AS order_nr,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COALESCE(ci.nr_order, 0) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE
        mh.production_year >= 2000
        AND mh.title IS NOT NULL
)
SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    CASE 
        WHEN fm.rn = 1 THEN 'Main Role'
        ELSE 'Supporting Role'
    END AS role_category,
    (SELECT COUNT(DISTINCT mk.keyword_id)
     FROM movie_keyword mk
     WHERE mk.movie_id = fm.movie_id) AS keyword_count,
    (SELECT STRING_AGG(kn.keyword, ', ' ORDER BY kn.keyword)
     FROM movie_keyword mk
     JOIN keyword kn ON mk.keyword_id = kn.id
     WHERE mk.movie_id = fm.movie_id) AS keywords,
    CAST(COALESCE(ff.info, 'Unknown') AS text) AS info
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info ff ON fm.movie_id = ff.movie_id AND ff.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    fm.order_nr IS NOT NULL
    AND fm.title NOT LIKE '%Bizarre%'
    AND NOT EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = fm.movie_id AND mc.note LIKE '%documentary%')
ORDER BY 
    fm.production_year DESC,
    fm.movie_id;

This SQL query showcases a comprehensive use of various constructs, including:

1. **Common Table Expressions (CTEs)**:
   - A recursive CTE (`MovieHierarchy`) builds a hierarchy of movies based on linked relationships.
   - A filtered CTE (`FilteredMovies`) to gather relevant movie data and associate order numbers.

2. **Window Functions**:
   - The use of `ROW_NUMBER()` to rank roles within each movie.

3. **NULL Logic**:
   - `COALESCE` functions battle against potential NULL values in casting.

4. **Subqueries**:
   - Counting keywords and gathering keyword details through correlated subqueries and aggregates.

5. **String Functions**:
   - `STRING_AGG` to concatenate keywords.

6. **Complicated Predicates**:
   - Filtering conditions dealing with NULLs, LIKE clauses, and subquery exclusions to enhance the selection criteria.

7. **Outer Joins**:
   - LEFT JOINs to ensure that movies without specific information can still be included.

This query efficiently combines numerous SQL features, aligning with performance benchmarking objectives by demonstrating comprehensive SQL capabilities.
