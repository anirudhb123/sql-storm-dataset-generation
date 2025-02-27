WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        rt.role AS role_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
TopRatedActors AS (
    SELECT 
        actor_roles.actor_name,
        COUNT(DISTINCT actor_roles.movie_id) AS movie_count,
        SUM(CASE WHEN actor_roles.nr_order = 1 THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        ActorRoles actor_roles
    JOIN 
        TopMovies tm ON actor_roles.movie_id = tm.movie_id
    GROUP BY 
        actor_roles.actor_name
    HAVING 
        COUNT(DISTINCT actor_roles.movie_id) > 2
)
SELECT 
    tm.title,
    tm.production_year,
    tra.actor_name,
    tra.movie_count,
    tra.lead_roles,
    COALESCE(mg.genres, 'No Genre') AS genres,
    (CASE 
        WHEN tra.lead_roles > 0 THEN 'Lead Actor'
        ELSE 'Supporting Actor'
     END) AS actor_standing
FROM 
    TopMovies tm
LEFT JOIN 
    TopRatedActors tra ON tm.movie_id = tra.movie_id
LEFT JOIN 
    MovieGenres mg ON tm.movie_id = mg.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;

This complex SQL query incorporates the following elements:
- **Common Table Expressions (CTEs):** `RankedMovies`, `TopMovies`, `ActorRoles`, `MovieGenres`, and `TopRatedActors` are used to structure the query and improve readability.
- **Window Functions:** `ROW_NUMBER()` is used to rank movies by production year.
- **Outer Joins:** `LEFT JOIN`s are used to pull in actors and genres.
- **Aggregate Functions:** Count and sum functions aggregate movies and lead roles.
- **String Aggregation:** `GROUP_CONCAT` gathers genres together in one field.
- **CASE Statements:** Used for conditional logic on actor standings based on lead roles.
- **NULL Handling:** `COALESCE` is used to replace NULL genres with 'No Genre'.
- **Subqueries and joins**: Join relationships are established across multiple tables to create a complex relationship structure for movies, actors, and their roles.

This results in a rich dataset that provides insights into top movies, their release year, the actors involved, their roles, and associated genres.
