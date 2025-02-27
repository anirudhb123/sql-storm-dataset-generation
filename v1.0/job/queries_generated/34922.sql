WITH RECURSIVE ActorMovieCount AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        person_id,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) as rank
    FROM 
        ActorMovieCount
),
TitleGenres AS (
    SELECT 
        t.id AS title_id,
        t.title,
        k.keyword,
        t.production_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IS NOT NULL
)
SELECT 
    ta.person_id,
    an.name,
    COUNT(DISTINCT tc.title_id) AS titles_joined,
    STRING_AGG(DISTINCT tg.keyword, ', ') AS genres,
    AVG(y.production_year) AS avg_prod_year,
    CASE 
        WHEN COUNT(*) = 0 THEN 'No Titles'
        ELSE 'Has Titles'
    END AS title_status
FROM 
    TopActors ta
JOIN 
    aka_name an ON ta.person_id = an.person_id
LEFT JOIN 
    (SELECT 
         title_id, 
         COUNT(DISTINCT c.movie_id) AS movie_count 
     FROM 
         complete_cast c 
     GROUP BY 
         title_id) tc ON tc.title_id = ta.person_id
LEFT JOIN 
    TitleGenres tg ON tg.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
LEFT JOIN 
    title y ON y.id = tg.title_id 
WHERE 
    ta.rank <= 10
GROUP BY 
    ta.person_id, an.name
HAVING 
    AVG(y.production_year) > 2000
ORDER BY 
    titles_joined DESC;

This SQL query performs several complex operations:

1. **Recursive CTE**: `ActorMovieCount` calculates the number of distinct movies for each actor based on their IDs from `aka_name` and the `cast_info` table.
2. **Ranking**: `TopActors` ranks these actors based on the movie count.
3. **Join with Keywords**: `TitleGenres` retrieves movie titles associated with various genres from the `movie_keyword` and `keyword` tables.
4. **Aggregation**: It counts the number of unique titles each actor has starred in, aggregates the various genres, and calculates the average production year of these titles.
5. **Conditional Expression**: Uses a `CASE` statement to determine if an actor has titles or not, setting a corresponding status.
6. **JOINs**: Utilizes multiple joins (both inner and left) to combine data from various tables while also demonstrating NULL handling through outer joins.
7. **HAVING Clause**: Further filters the results to those actors with an average production year later than 2000.

This query effectively models a wide range of SQL features to extract meaningful information from the movie database schema, ideal for performance benchmarking.
