WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorFilmCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS film_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        afc.film_count
    FROM 
        aka_name a
    JOIN 
        ActorFilmCounts afc ON a.person_id = afc.person_id
    WHERE 
        afc.film_count > (
            SELECT 
                AVG(film_count)
            FROM 
                ActorFilmCounts
        )
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ta.name AS top_actor,
    COALESCE(mk.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN LENGTH(mk.keywords) - LENGTH(REPLACE(mk.keywords, ',', '')) + 1
        ELSE 0
    END AS keyword_count,
    ROW_NUMBER() OVER (ORDER BY tm.production_year DESC) AS movie_rank
FROM 
    RankedMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
JOIN 
    TopActors ta ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = tm.title_id 
        AND ci.person_id = ta.person_id
    )
WHERE 
    tm.rank_year <= 10  -- Get only the first 10 movies per year
ORDER BY 
    tm.production_year DESC,
    keyword_count DESC;

This SQL query gathers and processes data from multiple tables, incorporating various SQL features:

1. **Common Table Expressions (CTEs)**: Used to simplify complex queries by breaking down components:
   - `RankedMovies`: Gets titles and their ranks by year.
   - `ActorFilmCounts`: Counts the number of films each actor has appeared in.
   - `TopActors`: Selects actors who have appeared in above-average films.
   - `MovieKeywords`: Aggregates keywords for movies.

2. **Window Functions**: Such as `ROW_NUMBER()` to rank movies and actors.

3. **Outer Joins**: A `LEFT JOIN` between movies and keywords allows retrieval of titles even if they lack corresponding keywords.

4. **Correlated Subqueries**: Used to determine if an actor has acted in a specific movie.

5. **Group Aggregation**: `STRING_AGG()` collects multiple keywords per movie.

6. **Conditional Logic**: Uses `CASE` to categorize release years and count keywords connected to a movie.

7. **NULL Handling**: `COALESCE()` is used to replace any null keyword results with a default message.

8. **Complicated Predicate Logic**: The query extracts movies based on ranks while ensuring it only gathers top actors' contribution.

This elaborate query optimally demonstrates SQL's capabilities in processing complex data structures and relationships.
