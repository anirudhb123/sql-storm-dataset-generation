
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        LISTAGG(keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
    FROM 
        RankedMovies
    WHERE 
        keyword_rank <= 5 
    GROUP BY 
        movie_id, title, production_year
),
PopularActors AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order <= 5
    GROUP BY 
        c.movie_id, a.name
    HAVING 
        COUNT(c.person_id) > 1
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.keywords,
        pa.actor_name,
        pa.role_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        PopularActors pa ON tm.movie_id = pa.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    COALESCE(md.actor_name, 'No prominent actors') AS actor_name,
    COALESCE(md.role_count, 0) AS role_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.keywords;
