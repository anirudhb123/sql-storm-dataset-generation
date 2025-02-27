WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select movies and their immediate cast
    SELECT 
        m.id AS movie_id,
        m.title,
        c.person_id,
        1 AS depth
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000  -- Filter for modern movies
    UNION ALL
    -- Recursive case: find cast members of the cast members
    SELECT 
        mh.movie_id,
        m.title,
        c.person_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info c ON mh.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        m.production_year >= 2000
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT mh.person_id) AS total_cast,
        COUNT(DISTINCT ka.name) AS aka_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        aka_name ka ON mh.person_id = ka.person_id
    GROUP BY 
        mh.movie_id, mh.title
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.total_cast,
        ms.aka_count,
        RANK() OVER (ORDER BY ms.total_cast DESC) AS rank_total_cast,
        RANK() OVER (ORDER BY ms.aka_count DESC) AS rank_aka_count
    FROM 
        MovieStats ms
)
SELECT 
    tm.title,
    tm.total_cast,
    tm.aka_count,
    (tm.total_cast + COALESCE(tm.aka_count, 0)) AS combined_score,
    CASE 
        WHEN tm.rank_total_cast = 1 AND tm.rank_aka_count = 1 THEN 'Top Movie'
        WHEN tm.rank_total_cast <= 10 THEN 'Top Cast Movie'
        ELSE 'Regular Movie'
    END AS movie_category
FROM 
    TopMovies tm
WHERE 
    tm.rank_total_cast <= 10 
    OR tm.rank_aka_count <= 5
ORDER BY 
    combined_score DESC;
This SQL query:

1. Uses a recursive common table expression (CTE) `MovieHierarchy` to find all cast members of movies starting from the year 2000 and their connections.
2. The second CTE `MovieStats` aggregates the total cast members and the associated alternative names (aka) for each movie.
3. The `TopMovies` CTE ranks the movies based on their total cast and aka count.
4. Finally, the main query selects the top movies with categories based on their rankings and combines the metrics into a `combined_score` for detailed insights.

The query showcases a variety of SQL constructs, including recursive CTEs, window functions, conditional expressions, and joined data across multiple tables.
