WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(CAST(COUNT(DISTINCT ci.id) AS TEXT), 'No Cast') AS total_cast,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS companies,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS rn,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(mh.production_year AS VARCHAR)
    END AS display_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC, total_cast DESC
LIMIT 50 OFFSET 0;

### Description of Query Constructs:
- **CTE (Common Table Expression):** A recursive CTE `MovieHierarchy` builds a hierarchy of linked movies.
- **Left Joins:** `LEFT JOIN` constructs ensure that even if a movie has no cast or keywords, it is still included in the results.
- **Aggregations:** Counts of distinct cast members and keywords, and a string aggregation of company names.
- **Window Functions:** `ROW_NUMBER()` assigns a rank within groups of movies, ordered by production year.
- **NULL Logic:** The `COALESCE` function handles potential NULL results for cast count.
- **Complicated Expressions:** A `CASE` statement determines how to display the production year with special handling for NULLs.
- **HAVING Clause:** Filters to only include movies produced within a specific range (2000-2023).
- **String Expressions:** `STRING_AGG` is used to concatenate company names into a single string. 

This query is designed to aggregate rich information about films, focusing on linking and company data, while also providing insights into the cast and keywords associated with each movie in a structured output.
