WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year > 1990
        AND (k.keyword IS NULL OR LENGTH(k.keyword) > 0)
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        rn
    FROM 
        RecursiveMovieCTE cte
    JOIN 
        aka_title mt ON cte.movie_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year < 2023
)
SELECT 
    p.id AS person_id,
    n.name AS person_name,
    ARRAY_AGG(DISTINCT rm.title) AS movies,
    COUNT(DISTINCT rm.movie_id) AS total_movies,
    (SELECT COUNT(DISTINCT v.person_id) 
     FROM cast_info v 
     WHERE v.movie_id IN (SELECT DISTINCT movie_id FROM RecursiveMovieCTE) 
     AND v.person_id IS NOT NULL 
     AND v.nr_order BETWEEN 1 AND 5) AS frequent_cast_members,
    CASE 
        WHEN n.gender = 'F' THEN 'Female'
        WHEN n.gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender_description,
    MAX(CASE WHEN rm.production_year IS NOT NULL THEN rm.production_year ELSE 0 END) AS latest_movie_year
FROM 
    name n
JOIN 
    cast_info c ON n.id = c.person_id 
LEFT JOIN 
    RecursiveMovieCTE rm ON c.movie_id = rm.movie_id
WHERE 
    n.name IS NOT NULL 
    AND EXISTS (SELECT 1 FROM aka_name an WHERE an.person_id = n.id)
GROUP BY 
    p.id, n.name, n.gender
HAVING 
    COUNT(DISTINCT rm.movie_id) > 2
ORDER BY 
    total_movies DESC, n.name;

### Explanation:
1. **Common Table Expression (CTE)**: The `RecursiveMovieCTE` retrieves movies released after 1990 with keywords, ensuring that if a keyword is missing, it defaults to 'No Keyword'. It recursively pulls movie data while respecting the production year constraints.

2. **Main Query**: 
   - Joins the `name` and `cast_info` tables to associate actors with their movies.
   - Utilizes `LEFT JOIN` with the `RecursiveMovieCTE` for retrieving movie details.
   - Summarizes movie titles into an array and counts total distinct movies per person.
   - A correlated subquery is used to count frequent cast members for a movie's first five roles.
   - Gender is classified with a `CASE` statement, handling obscure values gracefully.
   - `HAVING` filters the final results to include only those who have acted in more than two movies.

3. **Sorting**: The final results are ordered first by the total number of movies in descending order and then by the person's name alphabetically, enabling quick insights into prolific actors.
