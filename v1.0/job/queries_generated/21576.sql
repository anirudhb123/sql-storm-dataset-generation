WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
        INNER JOIN cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL 
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        mv.title_id,
        mv.title,
        mv.production_year,
        COALESCE(pc.movie_count, 0) AS popular_actor_count
    FROM 
        RankedMovies mv
        LEFT JOIN (
            SELECT 
                ci.movie_id,
                COUNT(DISTINCT ak.person_id) AS movie_count
            FROM 
                cast_info ci
                JOIN aka_name ak ON ci.person_id = ak.person_id
            WHERE 
                ak.name IS NOT NULL
            GROUP BY 
                ci.movie_id
        ) pc ON mv.title_id = pc.movie_id
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        STRING_AGG(pa.name, ', ') AS popular_actors
    FROM 
        MovieDetails md
        LEFT JOIN PopularActors pa ON pa.movie_count > md.popular_actor_count
    GROUP BY 
        md.title, md.production_year
)
SELECT 
    fo.title,
    fo.production_year,
    fo.popular_actors,
    CASE 
        WHEN fo.popular_actors IS NULL THEN 'No popular actors'
        ELSE 'Has popular actors'
    END AS actor_status
FROM 
    FinalOutput fo
WHERE 
    fo.production_year >= 2000
ORDER BY 
    fo.production_year DESC, fo.title;

This SQL query performs the following:

1. Creates a CTE `RankedMovies` to rank movies by title within their production year.
2. Defines another CTE `PopularActors` to identify actors associated with more than five movies.
3. Assembles `MovieDetails` to get titles and production years along with the count of popular actors for each movie.
4. Forms a final output with `FinalOutput`, which joins movie details and aggregates names of popular actors.
5. The final selection filters recent movies (from the year 2000 onward) and includes a case statement to indicate the presence of popular actors. 

This query is designed for performance benchmarking, testing complex join orders, grouping, and filtering logic.
