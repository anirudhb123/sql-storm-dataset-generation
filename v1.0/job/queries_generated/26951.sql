WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year >= 2000 -- consider movies from 2000 onwards
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredActors AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    WHERE 
        ak.name LIKE '%Smith%' -- filter actors with 'Smith' in their name
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(fa.actor_name, ', ') AS actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredActors fa ON EXISTS (
            SELECT 1 
            FROM cast_info ci 
            WHERE ci.movie_id = rm.movie_id AND ci.person_id = fa.person_id
        )
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count
)

SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.cast_count, 
    md.actors
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 5 -- movies with more than 5 cast members
ORDER BY 
    md.production_year DESC, md.cast_count DESC; -- order by latest production year and then by cast count
