WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(a.title) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
TopRankedMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        t.movie_title,
        t.production_year,
        c.name AS actor_name,
        rc.role AS role_description,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        TopRankedMovies t
    JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM title WHERE title = t.movie_title AND production_year = t.production_year LIMIT 1)
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name c ON c.person_id = ci.person_id
    JOIN 
        role_type rc ON rc.id = ci.role_id
    JOIN 
        movie_keyword mk ON mk.movie_id = cc.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.movie_title,
        t.production_year,
        c.name,
        rc.role
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.role_description,
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    LENGTH(md.movie_title) DESC;
