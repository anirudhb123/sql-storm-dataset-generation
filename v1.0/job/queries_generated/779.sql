WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COALESCE(SUM(mni.info = 'box office' AND mni.note IS NOT NULL), 0) AS total_box_office,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mni ON t.movie_id = mni.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title,
        production_year,
        actor_count,
        total_box_office,
        all_actors,
        RANK() OVER (ORDER BY total_box_office DESC) AS revenue_rank
    FROM 
        MovieDetails
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.total_box_office,
    tm.all_actors,
    CASE 
        WHEN total_box_office IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Available' 
    END AS revenue_status
FROM 
    TopMovies tm
WHERE 
    tm.revenue_rank <= 10
ORDER BY 
    tm.total_box_office DESC;
