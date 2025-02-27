WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.title ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_acted
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name, a.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), MovieGenres AS (
    SELECT 
        mt.title, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.title ORDER BY k.keyword) AS genre_rank
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), NullCheck AS (
    SELECT 
        *,
        CASE 
            WHEN movies_acted IS NULL THEN 'No Movies' 
            ELSE 'Movies Available' 
        END AS availability
    FROM 
        ActorInfo
)
SELECT 
    RM.title,
    RM.production_year,
    RM.num_cast,
    AI.actor_name,
    AI.movies_acted,
    MG.keyword AS genre,
    MG.genre_rank,
    NC.availability
FROM 
    RankedMovies RM
LEFT JOIN 
    NullCheck NC ON RM.rank = 1
LEFT JOIN 
    ActorInfo AI ON AI.movies_acted > 10
LEFT JOIN 
    MovieGenres MG ON RM.title = MG.title
WHERE 
    RM.production_year > 2000 
    AND (AI.movies_acted IS NULL OR AI.movies_acted > 3)
ORDER BY 
    RM.production_year DESC, 
    RM.num_cast DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;

This query defines a complex structure of Common Table Expressions (CTEs) to benchmark performance across the various entities in the `Join Order Benchmark` schema. Key elements include:

1. **RankedMovies**: Calculates the number of cast members per movie and ranks them by the number of distinct actors.
2. **ActorInfo**: Aggregates actors who have appeared in more than 5 movies, giving insights into prolific performers.
3. **MovieGenres**: Associates movies with their genres while assigning a rank to that association.
4. **NullCheck**: Checks for NULL values in the count of movies acted by an actor and provides a semantic message.

The final SELECT statement utilizes these CTEs to produce an interesting output. It filters, orders, and limits results, showcasing various advanced SQL features, including window functions, outer joins, correlated subqueries, and case logic.
