WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(ek.id, 0) AS episode_id,
        COALESCE(ek.season_nr, -1) AS season_number,
        COALESCE(ek.episode_nr, -1) AS episode_number
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_title ek ON mt.episode_of_id = ek.id

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(ek.id, 0),
        COALESCE(ek.season_nr, -1),
        COALESCE(ek.episode_nr, -1)
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    CASE 
        WHEN mv.production_year IS NOT NULL THEN mv.production_year
        ELSE 'Unknown Year'
    END AS release_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    SUM(CASE WHEN it.info IS NOT NULL THEN 1 ELSE 0 END) AS total_info_types,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mv.production_year DESC) AS row_num
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
LEFT JOIN 
    movie_info mv ON at.movie_id = mv.movie_id
LEFT JOIN 
    movie_companies mc ON at.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_idx it ON mv.movie_id = it.movie_id AND mv.info_type_id = it.info_type_id
WHERE 
    at.production_year BETWEEN 1980 AND 2023
AND 
    (a.name IS NOT NULL OR a.name_pcode_nf IS NOT NULL)
GROUP BY 
    a.id, at.title, mv.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 OR SUM(CASE WHEN it.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    row_num, release_year DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation of Constructs Used:

1. **CTE (Common Table Expression)**: The recursive CTE `movie_hierarchy` is used to build a hierarchy of movies and their episodes, which can help in analyzing series with multiple seasons/episodes.
  
2. **LEFT JOINs**: These are used to join different tables while ensuring that results are returned even if there are missing matches.

3. **CASE Statements**: Utilized to handle NULLs and to create custom outputs based on conditions, demonstrating handling of NULL logic.

4. **COUNT and SUM with CASE**: Calculating distinct production companies and the total info types conditionally showcases aggregate functions and predicates.

5. **ROW_NUMBER Window Function**: Used to differentiate entries per actor by movie release year, allowing for ordered results per partition.

6. **HAVING Clause**: Filters aggregated results based on certain conditions which can lead to intriguing insights into actors involved in multiple productions.

7. **OFFSET and FETCH**: Implements pagination to get a subset of results, which can be useful in benchmarking queries to see performance over ranges.

8. **Bizarre SQL Semantics**: Use of `COALESCE` for ensuring clean outputs, particularly for nullable episodic data. Also, the OFFSET-FETCH at the end creates a potential corner case scenario where result sets vary based on "pages" rather than completion of the query.

This query is designed to be rich and elaborate, providing various complexities suitable for performance benchmarking within the provided schema.
