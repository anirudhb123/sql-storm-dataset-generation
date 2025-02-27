WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        aka_title a
    LEFT JOIN
        cast_info ca ON a.id = ca.movie_id
    LEFT JOIN
        aka_name ak ON ca.person_id = ak.person_id
    WHERE
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year, a.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        movie_id,
        actor_count,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(t.actor_count, 0) AS total_actors,
    COALESCE(t.actor_names, 'No Actors') AS actors,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies t
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.rank <= 10
GROUP BY 
    t.title, t.production_year, t.actor_count, t.actor_names
ORDER BY 
    total_actors DESC;
