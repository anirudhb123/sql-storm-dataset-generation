WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        CAST(COALESCE(ri.role, 'Unknown Role') AS text) AS role,
        COUNT(c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type ri ON c.role_id = ri.id
    GROUP BY 
        a.person_id, a.name, ri.role
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.name AS actor_name,
    a.role,
    a.movie_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    ActorRoles a ON a.movie_count > 10 AND EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.movie_id = r.movie_id AND ci.person_id = a.person_id
    )
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = r.movie_id
WHERE 
    r.title_rank = 1
ORDER BY
    r.production_year DESC,
    r.title ASC
LIMIT 100;

### Explanation:

- **Common Table Expressions (CTEs)**: 
  - **RankedMovies**: Ranks movies by their title within each production year.
  - **ActorRoles**: Aggregates actor information with their roles and counts the movies they are involved in.
  - **MovieKeywords**: Concatenates all keywords associated with each movie.

- **LEFT JOINs**: Used to join the `ActorRoles` and `MovieKeywords` CTEs with the `RankedMovies` CTE, allowing NULL values for non-matching records.

- **EXISTS Correlated Subquery**: Checks that an actor has a role in the movie being processed.

- **COALESCE for NULL Logic**: Manages cases where no keywords are found for movies.

- **Complicated Predicates/Expressions**: 
  - The condition on actor count ensures only actors involved in more than 10 movies are included. 

- **Window Functions**: RANK() function is used for assigning ranks to movie titles by year.

- **String Aggregation**: STRING_AGG is used to compile all keywords into a single string for each movie.

- **ORDER BY and LIMIT**: Sorts results by production year in descending order and limits the output to the top 100 movies. 

This query combines various complex SQL constructs and logic to yield valuable insights, perfect for performance benchmarking.
