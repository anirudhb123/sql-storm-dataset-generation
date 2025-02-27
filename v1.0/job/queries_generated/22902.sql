WITH RecursiveActorCount AS (
    SELECT 
        ci.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci 
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),
RankedActors AS (
    SELECT 
        person_id, 
        movie_count, 
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        RecursiveActorCount
),
TopActors AS (
    SELECT 
        ra.person_id, 
        ra.movie_count,
        an.name AS actor_name
    FROM 
        RankedActors ra
    JOIN 
        aka_name an ON ra.person_id = an.person_id
    WHERE 
        ra.actor_rank <= 10
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS description
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    GROUP BY 
        mt.id
),
ActorsMovies AS (
    SELECT 
        ta.actor_name,
        mi.title,
        mi.production_year,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        TopActors ta
    JOIN 
        cast_info ci ON ta.person_id = ci.person_id
    JOIN 
        MovieInfo mi ON ci.movie_id = mi.movie_id
    WHERE 
        mi.production_year IS NOT NULL
    GROUP BY 
        ta.actor_name, mi.title, mi.production_year
),
FinalResults AS (
    SELECT 
        actor_name,
        title,
        production_year,
        total_movies,
        CASE 
            WHEN total_movies IS NULL THEN 'No Movie Appearances'
            ELSE 'Appeared in ' || total_movies || ' Movies'
        END AS appearance_statement
    FROM 
        ActorsMovies
)
SELECT 
    fr.actor_name,
    fr.title, 
    fr.production_year,
    fr.appearance_statement,
    COALESCE(NULLIF(fr.appearance_statement, 'No Movie Appearances'), 'N/A') AS final_statement
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.total_movies DESC;
