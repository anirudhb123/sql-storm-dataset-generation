WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithLinks AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        ml.linked_movie_id,
        lt.link AS link_type
    FROM 
        aka_title at
    LEFT JOIN 
        movie_link ml ON at.id = ml.movie_id
    LEFT JOIN 
        link_type lt ON ml.link_type_id = lt.id
),
FilteredMovies AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.cast_count,
        mk.keywords,
        COALESCE(ml.link_type, 'No Links') AS link_info
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieKeywords mk ON m.production_year = (
            SELECT MAX(production_year) 
            FROM RankedMovies 
            WHERE year_rank = 1
        )
    LEFT JOIN 
        MoviesWithLinks ml ON m.production_year = (
            SELECT MAX(mv.production_year)
            FROM MoviesWithLinks mv
            WHERE mv.movie_id = m.movie_id
        )
    WHERE 
        m.cast_count IS NOT NULL
        AND m.cast_count > (
            SELECT AVG(castCount) 
            FROM (SELECT COUNT(ci.person_id) AS castCount 
                  FROM cast_info ci 
                  GROUP BY ci.movie_id) AS avgCount
        )
)
SELECT 
    f.movie_title,
    f.production_year,
    f.cast_count,
    f.keywords,
    f.link_info
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.cast_count DESC;

This SQL query uses Common Table Expressions (CTEs) to segment the task into logical parts:

- `RankedMovies`: Generates a ranked list of movies based on their production year and count of cast members.
- `MovieKeywords`: Aggregates keywords associated with each movie into a single string for easier display.
- `MoviesWithLinks`: Identifies movies that have links to other movies, capturing the type of links used.
- `FilteredMovies`: Combines all previous results, filters movies with a higher than average cast count, and prepares the final dataset.

The final `SELECT` statement retrieves the relevant details about the movies, sorting them in descending order by their production year and then by the count of their cast members, while ensuring a comprehensive output showcasing the movie title, production year, cast count, keywords, and links to other movies, if present.
