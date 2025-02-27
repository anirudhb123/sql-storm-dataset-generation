WITH RecursiveActorMovie AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        t.title AS movie_title,
        RANK() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
LatestMovies AS (
    SELECT 
        person_id, 
        actor_name, 
        movie_title
    FROM 
        RecursiveActorMovie
    WHERE 
        rank = 1
),
MovieDetails AS (
    SELECT 
        lm.actor_name,
        lm.movie_title,
        COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
        COALESCE(mi.info, 'No Details Available') AS movie_info,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY lm.actor_name ORDER BY lm.movie_title) AS movie_order
    FROM 
        LatestMovies lm
    LEFT JOIN 
        movie_keyword mk ON lm.movie_title = mk.movie_id
    LEFT JOIN 
        movie_info mi ON lm.movie_title = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON lm.movie_title = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    actor_name,
    movie_title,
    movie_keyword,
    movie_info,
    company_type,
    movie_order
FROM 
    MovieDetails
WHERE 
    (movie_keyword <> 'No Keywords' OR movie_info IS NOT NULL)
ORDER BY 
    actor_name, movie_order
FETCH FIRST 50 ROWS ONLY;

-- Adding a union with a bizarre case that includes random NULL values check
UNION ALL
SELECT 
    NULL AS actor_name,
    NULL AS movie_title,
    NULL AS movie_keyword,
    NULL AS movie_info,
    NULL AS company_type,
    NULL AS movie_order
WHERE 
    (SELECT COUNT(*) FROM name) = 0;

-- Final WHERE clause to check for any odd cases to demonstrate a semantic edge case
HAVING 
    COUNT(*) > 0 OR EXISTS (SELECT 1 FROM title WHERE production_year IS NULL);

This query does the following:
1. It uses Common Table Expressions (CTEs) to recursively find the latest movies associated with actors, applying ranks to order their production years.
2. It correlates this information with keywords, details about the movie, and company types.
3. It fetches relevant information but restricts results to actors and movies with associated keywords or additional details.
4. It adds an unusual UNION case that retrieves rows with NULL values when the count of entries in `name` is zero.
5. Lastly, it adds a HAVING clause to check for oddities in the production year data, showcasing bizarre SQL behavior.
