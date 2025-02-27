WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
PopularTitles AS (
    SELECT 
        movie_title,
        COUNT(*) AS actor_count
    FROM 
        RankedTitles
    WHERE 
        rn <= 3
    GROUP BY 
        movie_title
    HAVING 
        COUNT(*) >= 5
),
TopActors AS (
    SELECT 
        actor_name, 
        COUNT(*) AS movie_count
    FROM 
        RankedTitles
    WHERE 
        rn <= 3
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    ta.actor_name,
    pt.movie_title,
    pt.actor_count,
    rt.production_year
FROM 
    TopActors ta
JOIN 
    PopularTitles pt ON ta.actor_name IN (
        SELECT 
            a.name 
        FROM 
            aka_name a 
        JOIN 
            cast_info c ON a.person_id = c.person_id
        JOIN 
            aka_title t ON c.movie_id = t.movie_id
        WHERE 
            t.title = pt.movie_title
    )
JOIN 
    RankedTitles rt ON rt.actor_name = ta.actor_name AND rt.movie_title = pt.movie_title
ORDER BY 
    pt.actor_count DESC, ta.actor_name;

This SQL query performs a series of complex operations involving CTEs (Common Table Expressions) to analyze actors and movies, focusing on the actors with the most prolific recent performance and aggregating titles that have garnered multiple actors in prominent roles. The query ranks actors by their recent contributions to popular films whilst ensuring that only movies featuring at least five actors who are in the top ranks of recent contributions are included.
