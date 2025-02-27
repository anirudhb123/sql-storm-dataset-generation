WITH MovieRanked AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS role_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title_id, title, production_year, actor_count, role_count
    FROM 
        MovieRanked
    WHERE 
        rank <= 10
),
ActorNames AS (
    SELECT 
        a.person_id,
        a.name,
        t.title_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        TopMovies t ON c.movie_id = t.title_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    t.actor_count,
    t.role_count,
    CASE 
        WHEN t.actor_count > 5 THEN 'Ensemble Cast'
        WHEN t.actor_count = 0 THEN 'No Actors'
        ELSE 'Regular Cast'
    END AS cast_type
FROM 
    TopMovies t
LEFT JOIN 
    ActorNames a ON t.title_id = a.title_id
ORDER BY 
    t.production_year DESC, t.title;
