WITH RECURSIVE ActorMovies AS (
    SELECT 
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ka.name IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        ActorMovies am
    JOIN 
        movie_keyword mk ON am.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    GROUP BY 
        am.actor_name, am.movie_title, am.production_year
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies
    FROM 
        MoviesWithKeywords
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) >= 5
),
ActorDetails AS (
    SELECT 
        ta.actor_name,
        md.info AS additional_info
    FROM 
        TopActors ta
    LEFT JOIN 
        person_info md ON ta.actor_name = (SELECT name FROM aka_name WHERE person_id = (SELECT person_id FROM cast_info WHERE movie_id IN (SELECT movie_id FROM aka_title WHERE title = ta.actor_name)))
)
SELECT 
    mw.actor_name,
    mw.movie_title,
    mw.production_year,
    mw.keywords,
    ad.additional_info
FROM 
    MoviesWithKeywords mw
LEFT JOIN 
    ActorDetails ad ON mw.actor_name = ad.actor_name
WHERE 
    mw.keywords IS NOT NULL
    AND mw.production_year >= 2010
    AND (ad.additional_info LIKE '%winner%' OR ad.additional_info IS NULL)
ORDER BY 
    mw.production_year DESC,
    mw.actor_name;

In this SQL query, several advanced SQL constructs are utilized:

1. **Common Table Expressions (CTEs)**: Multiple recursive and non-recursive CTEs are defined to break down the complex logic into manageable parts.
2. **Window Functions**: The query utilizes `ROW_NUMBER()` to rank movies for each actor based on production year.
3. **String Aggregation**: The `STRING_AGG()` function is used to concatenate keywords associated with movies.
4. **NULL Logic**: The `LEFT JOIN` with `IS NULL` conditions demonstrates handling of NULL values.
5. **Complicated Predicates**: The final selection includes multiple conditions, including a check for keywords and production year.
6. **Subqueries**: Used in various parts of the CTEs and main query to correlate and derive necessary data.

This query aims to highlight actors with a significant number of movies while gathering metadata about those movies that match defined criteria, showcasing intricate SQL capabilities.
