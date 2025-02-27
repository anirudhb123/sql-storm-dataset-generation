WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
),
TopMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY 
        m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.total_cast
    FROM 
        TopMovies tm
    WHERE 
        tm.rn <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.total_cast,
    COALESCE(pi.info, 'No Info Available') AS person_info,
    COALESCE(cn.name, 'Unknown Company') AS company_name
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info mi ON f.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON mi.info_type_id = pi.info_type_id AND pi.person_id IS NOT NULL
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    f.total_cast > 10
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC;


### Explanation of the Query:
1. **CTE - MovieHierarchy**: This recursive common table expression fetches movies released from the year 2000 onwards, recursively linking movies to their sequels or related connections.
  
2. **CTE - TopMovies**: From the hierarchy established, this CTE computes the total number of cast members for each movie, ranking them per production year.

3. **CTE - FilteredMovies**: Filters the movies to only include the top 5 by cast count for each production year.

4. **Final SELECT**: The final select pulls data from the filtered results, incorporating movie info, person info, and company names, handling any potential NULL values gracefully using `COALESCE`.

5. **Complex Logic**: The query uses outer joins, window functions, correlated subqueries, filtering on `NULL` logic, and sorts the results by year and total cast.
