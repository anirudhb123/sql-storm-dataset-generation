WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN actor_count > 5 THEN 'Popular'
            ELSE 'Less Popular'
        END AS popularity,
        tg.kind AS genre
    FROM 
        RankedMovies rm
    LEFT JOIN 
        kind_type tg ON rm.title LIKE '%' || tg.kind || '%'
    WHERE 
        rm.actor_count IS NOT NULL
),
FinalStats AS (
    SELECT 
        fm.production_year,
        COUNT(fm.movie_id) AS total_movies,
        AVG(fm.actor_count) AS avg_actors,
        MAX(fm.actor_count) AS max_actors,
        STRING_AGG(DISTINCT fm.title, '; ') AS movie_titles
    FROM 
        FilteredMovies fm
    GROUP BY 
        fm.production_year
)
SELECT 
    fs.production_year,
    fs.total_movies,
    fs.avg_actors,
    fs.max_actors,
    movie_titles,
    (SELECT COUNT(*) FROM title WHERE production_year = fs.production_year AND imdb_id IS NOT NULL) as total_valid_imdb_ids,
    CASE 
        WHEN fs.total_movies = 0 THEN NULL
        ELSE ROUND((fs.avg_actors::decimal / fs.total_movies), 2)
    END AS avg_actors_per_movie
FROM 
    FinalStats fs
ORDER BY 
    fs.production_year DESC;

In this complex SQL query:
- We utilize Common Table Expressions (CTEs) to break down the query into more manageable parts:
  1. `RankedMovies` calculates a row number and actor count for each movie in each production year while aggregating actor names.
  2. `FilteredMovies` adds a popularity classification and joins it with genre information.
  3. `FinalStats` aggregates the information year-wise.
- The final query selects total movies, average actor counts, and maximum actor counts per production year.
- A correlated subquery checks for the existence of valid IMDb IDs for movies per production year.
- We implement NULL logic to handle cases where no movies might exist with average calculations. 
- We add string aggregation for actor names and movies for a comprehensive view.
- The use of filtering and string expressions adds complexity to the logic, ensuring we capture a broader array of cases and potential edge cases in the database schema.
