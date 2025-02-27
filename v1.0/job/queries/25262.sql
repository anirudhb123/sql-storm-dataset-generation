WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_list,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        actors_list,
        keywords_list
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)

SELECT 
    f.production_year,
    COUNT(*) AS total_movies,
    AVG(f.actor_count) AS avg_actors_per_movie,
    STRING_AGG(f.title, '; ') AS movies
FROM 
    FilteredMovies f
GROUP BY 
    f.production_year
ORDER BY 
    f.production_year DESC;
