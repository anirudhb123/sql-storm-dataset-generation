WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY r.nr_order) AS rank_order
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info r ON cc.subject_id = r.person_id
    WHERE 
        m.production_year > 2000 
        AND mi.info LIKE '%action%'
),
TopActors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT rm.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT rm.movie_id) > 5
    ORDER BY 
        movie_count DESC
)
SELECT 
    ta.name AS actor_name,
    ta.movie_count,
    ARRAY_AGG(DISTINCT rm.title) AS movies
FROM 
    TopActors ta
JOIN 
    RankedMovies rm ON ta.movie_count IS NOT NULL
GROUP BY 
    ta.name, ta.movie_count
ORDER BY 
    ta.movie_count DESC
LIMIT 10;

This SQL query does the following:
1. It first creates a common table expression (CTE) called `RankedMovies` which collects movies released after 2000 that have the keyword 'action' in their info. It ranks these movies by a certain order related to casting.
2. It then aggregates actor information in another CTE called `TopActors` to find actors involved in more than 5 of those movies, grouping them by the actor's name.
3. Finally, it selects the top 10 actors from `TopActors`, providing their name, count of movies, and a list of movies they were in. This engineered complexity can be useful for benchmarking string processing in SQL.
