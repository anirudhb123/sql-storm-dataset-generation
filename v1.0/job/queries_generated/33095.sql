WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        COUNT(ci.id) AS cast_count,
        AVG(pi.info) AS average_rating
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id AND it.info = 'rating'
    LEFT JOIN 
        (SELECT 
            pi.person_id, 
            AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN pi.info::numeric END) AS info
         FROM 
            person_info pi
         GROUP BY 
            pi.person_id) pi ON ci.person_id = pi.person_id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.cast_count, 0) AS total_cast,
    COALESCE(tm.average_rating, 0) AS average_rating,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    average_rating DESC, 
    total_cast DESC 
LIMIT 10;

### Explanation:
1. **CTE MovieHierarchy**: This is a recursive CTE that builds a hierarchy of movies based on their `episode_of_id`, allowing us to navigate through TV show episodes and their parent movies.
  
2. **TopMovies**: This CTE aggregates movie data by joining `cast_info` to count the number of cast members for each movie and joins `movie_info` to fetch the average rating per movie, calculated only from entries tagged with the info type 'rating'.

3. **Main Query**: It retrieves information from the `TopMovies` CTE, including:
   - Title and production year of the movie
   - Total cast count (using `COALESCE` to handle potential `NULL` results)
   - Average rating (also using `COALESCE`)
   - The type of company associated with the movie, joined to the `company_type` table.

4. **Ordering and Limiting**: It orders the results by average rating and total cast count, limiting the output to the top 10 results for performance benchmarking.
