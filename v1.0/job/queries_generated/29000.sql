WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
        AND t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
TopActors AS (
    SELECT 
        n.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name n
    JOIN 
        cast_info ci ON n.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        n.name
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    rm.title,
    rm.production_year,
    ta.actor_name,
    ta.movie_count
FROM 
    RankedMovies rm
JOIN 
    TopActors ta ON ta.movie_count > 0
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;

In this query, we are creating a Common Table Expression (CTE) named `RankedMovies` that ranks movies based on the number of distinct cast members and filters for movies produced after the year 2000. We then create another CTE named `TopActors` which identifies the top 5 actors based on their appearance in the ranked movies. Finally, the main SELECT statement retrieves the titles of these ranked movies along with their production years and the names and movie counts of the top actors featured in them, ordering the results by year of production and cast count for clarity.
