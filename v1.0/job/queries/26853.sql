
WITH ActorMovieCount AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
MostProlificActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCount
    WHERE 
        movie_count >= (
            SELECT 
                AVG(movie_count)
            FROM 
                ActorMovieCount
        )
),
MovieDetails AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IN (SELECT actor_name FROM MostProlificActors)
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_names
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
