WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all top-level movies
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Find episodes corresponding to each movie
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1 AS level
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy h ON e.episode_of_id = h.movie_id
),
RankedMovies AS (
    -- Rank movies based on the production year and title
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        h.level,
        RANK() OVER (PARTITION BY h.level ORDER BY h.production_year DESC, h.title) AS rank
    FROM 
        MovieHierarchy h
)
SELECT 
    COALESCE(ak.name, 'Unknown') AS actor_name,
    m.title AS movie_title,
    m.production_year,
    m.level,
    r.rank,
    COUNT(k.id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    RankedMovies m
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = cc.subject_id
LEFT JOIN 
    movie_keyword k ON k.movie_id = m.movie_id
WHERE 
    m.level = 0 -- Only top-level movies
GROUP BY 
    ak.name, m.title, m.production_year, m.level, r.rank
HAVING 
    COUNT(k.id) > 1 -- Movies with more than one keyword
ORDER BY 
    m.production_year DESC, m.title, r.rank;

This SQL query utilizes various constructs:
- A recursive CTE to build a movie hierarchy including episodes.
- A window function (`RANK()`) to rank movies based on their production year and title within their respective levels.
- Outer joins to combine actors and movie keywords with the movie information.
- A `COALESCE` function to handle potential NULL values for actor names.
- Grouping and aggregation to count and concatenate keywords per movie.
- A `HAVING` clause to filter movies with more than one associated keyword.
