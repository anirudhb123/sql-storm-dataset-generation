WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
PersonDetails AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS movies_participated,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name, a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    pd.actor_name,
    pd.movies_participated,
    mk.keyword AS movie_keyword,
    COALESCE(mk.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    PersonDetails pd ON pd.movies_participated > 0
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn <= 5
    AND (pd.movies_participated IS NULL OR pd.movies_participated > 1)
ORDER BY 
    rm.production_year DESC, 
    pd.actor_name ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

### Explanation:
- **Common Table Expressions (CTEs):**
  - `RankedMovies`: Ranks movies by production year and calculates the count of cast members for each movie.
  - `PersonDetails`: Aggregates the count of movies participated by each actor while concatenating the titles into a comma-separated string, excluding NULL names.
  - `MovieKeywords`: Counts the occurrences of keywords for each movie.

- **Joins and Filters:**
  - LEFT JOINs are used to connect the movies, actors, and keywords while allowing for movies to appear even if they don't have associated actors or keywords.

- **Complicated Predicates:**
  - The WHERE clause checks for non-null production years and actor names and filters for movies with a rank of 5 or lower and at least one actor that has participated in more than one movie.

- **Window Functions:**
  - Utilizes ROW_NUMBER() to rank and COUNT() to determine the number of participants.

- **Set Operators:**
  - Although not explicitly used here, the query structure sets the foundation for potential UNION operations should one wish to combine different datasets.

- **NULL Logic:**
  - The use of COALESCE ensures that keyword counts default to zero if no keywords were found.

- **String Expressions:**
  - STRING_AGG aggregates movie titles into a single string for each actor. 

This SQL query aims to fetch a select few of the top movies (loosely defined here as the top 5 of each production year), highlight the active participants, and provide a summary of related keywords—all while handling complex relationships and potential NULLs.
