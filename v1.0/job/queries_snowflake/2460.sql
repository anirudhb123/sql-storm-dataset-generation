
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
Actors AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name a 
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 2
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT a.actor_name, ', ') WITHIN GROUP (ORDER BY a.actor_name) AS actor_list,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        Actors a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_list,
    md.keyword_count,
    CASE 
        WHEN md.production_year > 2000 THEN 'Modern'
        ELSE 'Classic'
    END AS era
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.keyword_count DESC
LIMIT 10;
