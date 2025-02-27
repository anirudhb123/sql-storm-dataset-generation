WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),
KeywordStats AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword kw ON mt.keyword_id = kw.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.level,
    ms.cast_count,
    ms.production_company_count,
    ks.keywords
FROM 
    MovieStats ms
LEFT JOIN 
    KeywordStats ks ON ms.movie_id = ks.movie_id
ORDER BY 
    ms.production_year DESC, 
    ms.level, 
    ms.cast_count DESC
LIMIT 50;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This Common Table Expression retrieves a hierarchy of movies where each movie can be linked to other movies (for example, sequels or prequels). It starts with movies of kind 'movie' and recursively links to related movies.

2. **Aggregate Counts (MovieStats)**: This section counts the number of unique cast members and production companies associated with each movie from the previous CTE. It uses a LEFT JOIN to ensure movies even without casts or companies are included.

3. **Keywords (KeywordStats)**: This CTE aggregates keywords for each movie into a comma-separated string using `STRING_AGG`.

4. **Final Select Statement**: The final query selects movie statistics, joining with the Keywords CTE and ordering by production year, hierarchy level, and cast count.

5. **LIMIT Clause**: The result is limited to 50 entries for efficiency in performance benchmarking.

This query structure allows for comprehensive analysis across the movie database while demonstrating varying SQL constructs.
