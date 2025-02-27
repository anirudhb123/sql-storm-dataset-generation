WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actor_list
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_title, production_year
),
MovieInfo AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        mi.info AS movie_note
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.movie_title = mi.info
)
SELECT 
    movie_title,
    production_year,
    actor_list,
    COALESCE(movie_note, 'No additional notes') AS movie_note
FROM 
    MovieInfo
ORDER BY 
    production_year DESC, movie_title;
