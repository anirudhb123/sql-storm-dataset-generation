WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        RankedTitles rt ON rt.title_id = c.movie_id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(am.actor_count, 0) AS actor_count,
        rt.title_rank
    FROM 
        aka_title m
    LEFT JOIN 
        ActorMovies am ON m.id = am.movie_id 
    JOIN 
        RankedTitles rt ON m.id = rt.title_id 
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
),
TopMovies AS (
    SELECT 
        title,
        actor_count,
        title_rank,
        DENSE_RANK() OVER(ORDER BY actor_count DESC) AS dense_rank
    FROM 
        FilteredMovies 
    WHERE 
        actor_count > 0
)
SELECT 
    f.title,
    f.actor_count,
    f.dense_rank,
    CASE 
        WHEN f.dense_rank <= 10 THEN 'Top 10 Movies'
        WHEN f.actor_count IS NULL THEN 'No Actors'
        ELSE 'Other'
    END AS movie_category,
    STRING_AGG(DISTINCT CONCAT('Actor ID: ', c.person_id, ', Role ID: ', c.role_id), '; ') AS actors_details
FROM 
    TopMovies f
LEFT JOIN 
    cast_info c ON f.title = (SELECT title FROM aka_title WHERE id = c.movie_id) 
GROUP BY 
    f.title, f.actor_count, f.dense_rank
ORDER BY 
    f.dense_rank;