WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Filtering for movies from the year 2000 onwards

    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cm.company_id) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY ah.name ORDER BY COUNT(cm.company_id) DESC) AS actor_rank
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    movie_companies cm ON mh.movie_id = cm.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ah.name IS NOT NULL
    AND (mh.production_year IS NOT NULL OR mh.production_year < 2023) -- NULL handling
GROUP BY 
    ah.name, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT k.id) > 2  -- Filter movies with more than 2 distinct keywords
ORDER BY 
    actor_rank, movie_title;

This query performs the following actions:
- Creates a recursive CTE `MovieHierarchy` to build a hierarchy of movies linked by `movie_link`, starting from movies produced after the year 2000.
- Selects actor names, movie titles, and production years from the last CTE.
- Aggregates keywords associated with each movie into a comma-separated string.
- Counts the number of companies associated with each movie.
- Ranks actors based on the count of different companies they have been associated with, using `ROW_NUMBER()` window function.
- Filters results to only include actors with non-null names and considers production years, with additional filtering for movies having more than two keywords.
- Orders the results by actor rank and then by movie title.
