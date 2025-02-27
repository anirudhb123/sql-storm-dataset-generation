WITH RECURSIVE FilmHierarchy AS (
    -- Start with all movies and their respective IDs and titles
    SELECT 
        t.id AS movie_id, 
        t.title, 
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL
    
    -- Recursively get linked movies for each movie
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        fh.level + 1
    FROM 
        FilmHierarchy fh
    JOIN 
        movie_link ml ON fh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT fh.movie_id) AS total_movies,
    SUM(CASE WHEN fh.level = 1 THEN 1 ELSE 0 END) AS direct_movies,
    AVG(CASE WHEN f.production_year IS NOT NULL THEN f.production_year END) AS avg_production_year,
    STRING_AGG(DISTINCT f.title, ', ') FILTER (WHERE f.title IS NOT NULL) AS movie_titles,
    MAX(CASE WHEN f.production_year IS NOT NULL THEN f.production_year ELSE NULL END) AS latest_year,
    MIN(CASE WHEN f.production_year IS NULL THEN 'Unknown Year' ELSE f.production_year::text END) AS earliest_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(fh.movie_id) DESC) AS rank_by_movies
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    FilmHierarchy fh ON ci.movie_id = fh.movie_id
LEFT JOIN 
    aka_title f ON fh.movie_id = f.id
LEFT JOIN 
    movie_keyword mk ON f.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, ak.person_id
HAVING 
    COUNT(DISTINCT fh.movie_id) > 3
ORDER BY 
    total_movies DESC, actor_name ASC
LIMIT 10;

**Explanation:**
- The `WITH RECURSIVE` clause starts a common table expression (`FilmHierarchy`) to gather movies and their linked counterparts.
- The main query retrieves actor names, counts the total movies they've acted in, counts direct movies, computes the average production year, aggregates all movie titles, determines the latest and earliest production year and counts associated keywords.
- `HAVING` is used to filter out actors with less than 4 total movies.
- The `ROW_NUMBER()` window function ranks actors by the number of movies in descending order.
- The final result is limited to the top 10 actors.
