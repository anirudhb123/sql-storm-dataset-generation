WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)

SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    (
        SELECT 
            STRING_AGG(DISTINCT n.name, ', ') 
        FROM 
            cast_info ci
        JOIN 
            aka_name n ON ci.person_id = n.person_id
        WHERE 
            ci.movie_id = (SELECT id FROM aka_title WHERE title = f.title AND production_year = f.production_year)
    ) AS lead_actors,
    CASE 
        WHEN f.actor_count > 10 THEN 'Ensemble Cast'
        WHEN f.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Few Actors'
    END AS cast_category
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.actor_count DESC;
