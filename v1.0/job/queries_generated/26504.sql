WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.id) DESC, t.production_year DESC) AS rank
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
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title AS movie_title,
        tm.production_year,
        a.name AS actor_name,
        r.role AS character_name,
        COUNT(mk.id) AS keyword_count,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords
    FROM 
        TopMovies tm
    JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        cast_info ci ON a.person_id = ci.person_id AND ci.movie_id = tm.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    GROUP BY 
        tm.title, tm.production_year, a.name, r.role
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.character_name,
    md.keyword_count,
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.actor_name;
