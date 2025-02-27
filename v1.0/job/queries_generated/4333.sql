WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id AND ci.person_role_id IS NOT NULL
    WHERE 
        t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        year_rank,
        COUNT(title) AS total_movies,
        AVG(actor_count) AS avg_actors_per_movie
    FROM 
        RankedMovies
    GROUP BY 
        year_rank
)
SELECT 
    ms.year_rank,
    ms.total_movies,
    ms.avg_actors_per_movie,
    (SELECT MAX(total_movies) FROM MovieStats) AS max_movies,
    (SELECT MIN(total_movies) FROM MovieStats) AS min_movies,
    COALESCE(MAX(CASE WHEN ms.total_movies > 50 THEN 1 ELSE 0 END), 0) AS high_volume_year,
    CASE 
        WHEN ms.avg_actors_per_movie > 10 THEN 'High'
        WHEN ms.avg_actors_per_movie > 5 THEN 'Medium'
        ELSE 'Low'
    END AS actor_density
FROM 
    MovieStats ms
GROUP BY 
    ms.year_rank, ms.total_movies, ms.avg_actors_per_movie
ORDER BY 
    ms.year_rank;
