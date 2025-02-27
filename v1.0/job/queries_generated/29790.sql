WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(mo.id) AS total_movies_linked,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_link mo ON a.id = mo.movie_id
    GROUP BY 
        a.id
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        kind_id, 
        cast_count, 
        total_movies_linked
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    kt.kind AS movie_kind,
    fm.cast_count,
    fm.total_movies_linked,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM 
    FilteredMovies fm
JOIN 
    aka_name ak ON ak.person_id IN (
        SELECT 
            DISTINCT c.person_id 
        FROM 
            cast_info c 
        WHERE 
            c.movie_id = fm.movie_id
    )
JOIN 
    kind_type kt ON fm.kind_id = kt.id
GROUP BY 
    fm.movie_id, fm.movie_title, fm.production_year, kt.kind, fm.cast_count, fm.total_movies_linked
ORDER BY 
    fm.cast_count DESC;

This query retrieves a ranked list of movies based on the number of distinct actors in the cast, limiting the results to the top 10 movies per kind. It also joins additional tables to gather movie types and lists the actors associated with each film. The use of `STRING_AGG` aggregates actor names into a comma-separated string for compact display.
