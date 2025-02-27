WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count,
        STRING_AGG(movie_title, ', ' ORDER BY production_year DESC) AS movie_list
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
    GROUP BY 
        actor_name
),
FilteredActors AS (
    SELECT 
        a.actor_name,
        a.movie_count,
        a.movie_list,
        CASE 
            WHEN a.movie_count > 10 THEN 'Veteran'
            WHEN a.movie_count BETWEEN 5 AND 10 THEN 'Established'
            ELSE 'Emerging'
        END AS actor_status 
    FROM 
        ActorMovieCount a
)
SELECT 
    f.actor_name,
    f.movie_count,
    f.movie_list,
    f.actor_status
FROM 
    FilteredActors f
WHERE 
    f.actor_status = 'Veteran'
ORDER BY 
    f.movie_count DESC;