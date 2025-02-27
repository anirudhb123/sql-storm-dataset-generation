WITH RECURSIVE MovieCTE AS (
    SELECT 
        a.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    INNER JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
        AND t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        m.level + 1,
        CAST(m.path || ' -> ' || t.title AS VARCHAR(255))
    FROM 
        MovieCTE m
    INNER JOIN 
        movie_link ml ON m.movie_id = ml.linked_movie_id
    INNER JOIN 
        aka_title t ON ml.movie_id = t.movie_id
    WHERE 
        t.production_year <= m.production_year
)
SELECT 
    ct.kind AS company_type,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    STRING_AGG(m.path, '; ') AS movie_paths,
    AVG(CASE WHEN m.production_year > 2000 THEN m.production_year END) AS avg_recent_year
FROM 
    MovieCTE m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ct.kind IS NOT NULL
GROUP BY 
    ct.kind
ORDER BY 
    movie_count DESC
LIMIT 10;


### Explanation of the Query:
1. **Recursive CTE (Common Table Expression)**: 
   - This query starts with a CTE named `MovieCTE` that recursively collects movies, their titles, production years, and paths, looking to link movies with their sequels or related content while filtering out movies produced in years lesser than 2000.

2. **Initial Part of the CTE**:
   - The initial CTE pulls data from `aka_title`, while joining `movie_companies` and `company_name` to include countries, ensuring that only relevant countries are included. 

3. **Recursion in the CTE**:
   - The recursive part continues to fetch linked movies, forming a path (a string that shows the linkage of titles) and expands the movie hierarchy based on relationships defined in `movie_link`.

4. **Main Select Statement**:
   - The final SELECT statement aggregates results to show the count of movies per company type with a condition where the production year is recent, and it simultaneously compiles all paths into a single string for readability.

5. **NULL Handling**:
   - The usage of `LEFT JOIN` ensures that companies without any linked movies still appear in the results.

6. **Output**:
   - The result is filtered to show only the top 10 company types based on their movie count in descending order, thereby providing insights into which companies are most active in creating new titles in recent years.
