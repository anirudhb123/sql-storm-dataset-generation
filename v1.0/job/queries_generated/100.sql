WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), 
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        AVG(production_year) AS avg_year
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
),
MovieStats AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.actor_name, ', ') AS actors_list
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.title
)
SELECT 
    a.actor_name,
    a.movie_count,
    a.avg_year,
    m.movie_title,
    m.actor_count,
    m.actors_list
FROM 
    ActorStats a
JOIN 
    MovieStats m ON m.actor_count > 3
ORDER BY 
    a.avg_year DESC, 
    a.movie_count DESC
LIMIT 50;
