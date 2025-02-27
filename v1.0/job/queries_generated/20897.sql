WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
ActorStatistics AS (
    SELECT 
        ca.person_id,
        a.name,
        COUNT(DISTINCT ca.movie_id) AS total_movies,
        MAX(t.production_year) AS last_movie_year
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        RankedTitles rt ON ca.movie_id = rt.title_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        ca.person_id, a.name
),
MoviesWithNotableActors AS (
    SELECT 
        rt.title,
        rt.production_year,
        as_stats.name,
        as_stats.total_movies,
        as_stats.last_movie_year
    FROM 
        RankedTitles rt
    JOIN 
        ActorStatistics as_stats ON rt.title_id = (
            SELECT 
                ca.movie_id 
            FROM 
                cast_info ca
            WHERE 
                ca.movie_id = rt.title_id
            ORDER BY 
                CASE 
                    WHEN as_stats.total_movies > 5 THEN 0 
                    ELSE 1 
                END, 
                ca.nr_order
            LIMIT 1
        )
    WHERE 
        rt.year_rank = 1 
        AND rt.total_titles > 3
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    CASE 
        WHEN a.last_movie_year IS NULL THEN 'No Movies'
        ELSE CONCAT('Last Seen in ', a.last_movie_year)
    END AS actor_status
FROM 
    MoviesWithNotableActors m
LEFT JOIN 
    ActorStatistics a ON m.name = a.name
ORDER BY 
    m.production_year DESC, 
    m.title;
