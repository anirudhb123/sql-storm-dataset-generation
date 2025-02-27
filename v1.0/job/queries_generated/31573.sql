WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mh.level ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    tm.title AS movie_title,
    tm.production_year,
    tm.cast_count,
    mk.keywords,
    COALESCE(AVG(pi.info_type_id), 0) AS average_info_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id IN (
        SELECT 
            DISTINCT c.person_id
        FROM 
            complete_cast c
        WHERE 
            c.movie_id = tm.movie_id
    )
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, mk.keywords
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

### Explanation:
- **CTE `MovieHierarchy`:** This recursive CTE builds a hierarchy of movies starting from those produced in the year 2000 and linking them based on relationships from the `movie_link` table.
  
- **CTE `TopMovies`:** It calculates the count of distinct cast members for each movie in the hierarchy and ranks them based on the number of cast members at each hierarchy level.

- **CTE `MovieKeywords`:** This aggregates the keywords associated with each movie.

- The final `SELECT` statement retrieves the top movies along with their production year, cast count, associated keywords, and the average information type ID of the cast members, filtering to only the top 10 movies by rank, ordered by production year and cast count.

- **Using string aggregation:** `STRING_AGG` is used to concatenate keywords into a single field.

- **COALESCE:** This is employed to handle cases where an average cannot be computed due to NULLs, ensuring a result of 0 is returned instead.

This query utilizes outer joins, window functions, set operators, subqueries, and a recursive CTE, making it a complex and rich benchmark for SQL performance testing.
