WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
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
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    tm.actor_count,
    (SELECT AVG(actor_count) FROM TopMovies) AS average_actor_count,
    CASE 
        WHEN tm.actor_count > (SELECT AVG(actor_count) FROM TopMovies) THEN 'Above Average'
        ELSE 'Below Average'
    END AS comparison_to_average
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year, tm.actor_count DESC;
