WITH ActorMovieStats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        COUNT(DISTINCT CASE WHEN c.role_id IS NOT NULL THEN c.movie_id END) AS acting_movies,
        AVG(CASE 
                WHEN c.nr_order IS NOT NULL THEN c.nr_order 
                ELSE NULL 
            END) AS avg_order,
        SUM(CASE 
                WHEN cm.kind IS NOT NULL THEN 1 
                ELSE 0 
            END) AS movie_company_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = c.movie_id
    LEFT JOIN 
        comp_cast_type cm ON c.person_role_id = cm.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
),
TopActors AS (
    SELECT 
        actor_id, 
        actor_name,
        total_movies,
        acting_movies,
        avg_order,
        movie_company_count,
        ROW_NUMBER() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorMovieStats
    WHERE 
        total_movies > 5
)
SELECT 
    t.actor_id, 
    t.actor_name, 
    t.total_movies, 
    t.acting_movies, 
    t.avg_order,
    COALESCE(t.movie_company_count, 0) AS company_count,
    CASE 
        WHEN t.avg_order IS NULL THEN 'No order data'
        WHEN t.avg_order > 5 THEN 'Prominent Actor'
        ELSE 'Supporting Actor'
    END AS actor_category
FROM 
    TopActors t
FULL OUTER JOIN 
    (SELECT 
         name, 
         COUNT(DISTINCT movie_id) AS movie_count 
     FROM 
         aka_name a
     JOIN 
         cast_info c ON a.person_id = c.person_id
     GROUP BY 
         name) AS OtherActors ON t.actor_name = OtherActors.name
WHERE 
    OtherActors.movie_count >= 3 OR t.actor_id IS NOT NULL
ORDER BY 
    t.total_movies DESC NULLS LAST, 
    OtherActors.movie_count DESC NULLS LAST;