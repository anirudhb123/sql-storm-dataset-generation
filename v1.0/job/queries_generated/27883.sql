WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count >= 5
),

MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.actor_count,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actors,
        GROUP_CONCAT(DISTINCT kn.keyword ORDER BY kn.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kn ON mk.keyword_id = kn.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.actor_count
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actors,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2010 AND 2020
ORDER BY 
    md.actor_count DESC, md.production_year ASC;
