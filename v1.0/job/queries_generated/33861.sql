WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        T.id AS movie_id,
        T.title AS movie_title,
        1 AS level
    FROM 
        aka_title T
    WHERE 
        T.production_year >= 2000  -- Focus on movies after the year 2000
    
    UNION ALL
    
    SELECT 
        ML.linked_movie_id,
        T.title,
        MH.level + 1
    FROM 
        MovieHierarchy MH
    JOIN 
        movie_link ML ON MH.movie_id = ML.movie_id
    JOIN 
        aka_title T ON ML.linked_movie_id = T.id
    WHERE 
        T.production_year >= 2000
)

SELECT 
    K.keyword,
    COUNT(DISTINCT MH.movie_id) AS movie_count,
    STRING_AGG(DISTINCT T.title, ', ') AS movie_titles,
    AVG(CASE WHEN P.gender = 'F' THEN 1 ELSE 0 END) AS female_percentage,
    SUM(CASE WHEN CC.kind IS NOT NULL THEN 1 ELSE 0 END) AS cast_count
FROM 
    MovieHierarchy MH
LEFT JOIN 
    movie_keyword MK ON MH.movie_id = MK.movie_id
LEFT JOIN 
    keyword K ON MK.keyword_id = K.id
LEFT JOIN 
    complete_cast CC ON MH.movie_id = CC.movie_id
LEFT JOIN 
    cast_info CI ON CC.subject_id = CI.person_id
LEFT JOIN 
    person_info P ON CI.person_id = P.person_id
LEFT JOIN 
    title T ON MH.movie_id = T.id
GROUP BY 
    K.keyword
HAVING 
    COUNT(DISTINCT MH.movie_id) > 1  -- Filter to show keywords for movies with multiple tags
ORDER BY 
    movie_count DESC
LIMIT 10;  -- Top 10 keywords based on movie counts

### Explanation:
1. **CTE (Common Table Expression)**: The `MovieHierarchy` CTE recursively gathers movies produced from the year 2000 onwards and gathers their linked titles.
  
2. **Joins**: 
    - `LEFT JOIN` is used for `movie_keyword`, `keyword`, `complete_cast`, `cast_info`, `person_info`, and `title`. This ensures that even if there are no keywords or cast members, results are still returned for the movies.

3. **Aggregations**:
    - `COUNT(DISTINCT MH.movie_id)` counts how many distinct movies are associated with each keyword.
    - `STRING_AGG(DISTINCT T.title, ', ')` aggregates the titles of the movies into a single string for easier readability.
    - The `AVG` calculates the percentage of female cast members by counting female roles.
    - The `SUM` counts how many cast members exist that have an associated role type.

4. **HAVING Clause**: Filters results to ensure only keywords associated with multiple movies are included.

5. **ORDER BY and LIMIT**: This orders the results by the number of associated movies and limits output to the top 10 keywords. 

This query serves as a performance benchmark due to its complexity, involving multiple joins, aggregations, and conditions that test the database's handling of large datasets and intricate relationships.
