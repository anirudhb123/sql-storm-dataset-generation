WITH RecursiveMovieCTE AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order IS NOT NULL

    UNION ALL

    SELECT 
        'Sequel to ' || movie_title,
        production_year + 1,
        c.person_id,
        a.name AS actor_name,
        cast_order + 1
    FROM 
        RecursiveMovieCTE r
    JOIN 
        cast_info c ON r.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        r.production_year < EXTRACT(YEAR FROM CURRENT_DATE) 
)

SELECT 
    m.movie_title,
    m.production_year,
    m.actor_name,
    COUNT(m.actor_name) OVER (PARTITION BY m.movie_title) AS actor_count,
    AVG(COALESCE(m.production_year - m.cast_order, 0)) OVER (PARTITION BY m.movie_title) AS avg_year_diff,
    STRING_AGG(DISTINCT COALESCE(LINK.note, 'N/A'), ', ') AS link_notes
FROM 
    RecursiveMovieCTE m
LEFT JOIN 
    movie_link ml ON m.production_year = ml.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = ml.linked_movie_id
LEFT JOIN 
    movie_info_idx mii ON mi.info_type_id = mii.info_type_id AND mii.info = 'Trivia'
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.production_year
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL 
WHERE 
    m.actor_name IS NOT NULL 
    AND m.production_year BETWEEN 1980 AND 2023 
GROUP BY 
    m.movie_title, m.production_year, m.actor_name
HAVING 
    COUNT(m.actor_name) > 2
ORDER BY 
    avg_year_diff DESC, actor_count DESC;

### Explanation of SQL Constructs Used

- **CTE (Common Table Expression)**: `RecursiveMovieCTE` generates a recursive list of movies with potential sequels by incrementing the production year and maintaining actor association.
  
- **ROW_NUMBER()**: Assigns a sequential number to each actor based on their order in the cast.
  
- **STRING_AGG**: Aggregates link notes into a single string, useful for combining related information.
  
- **COALESCE**: Used to handle NULL values in production year differences.
  
- **LEFT JOINs**: These are employed to gather additional information about linked movies and companies while ensuring that all movies appear in the result even if related info is missing.
  
- **Window Functions (AVG and COUNT)**: Calculate derived metrics over partitions of result sets, offering powerful analytical capabilities.
  
- **WHERE and HAVING clauses**: Filter results to focus on more relevant data, ensuring that only movies with sufficient cast members are displayed.
  
- **ORDER BY**: Sorts the result according to the average year difference and actor count to highlight interesting metrics in the data.

This query could be used to benchmark the performance of complex SQL constructs when run against large datasets typical of movie databases.
