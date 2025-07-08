
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
Directors AS (
    SELECT 
        c.movie_id,
        a.name AS director_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id 
    WHERE 
        r.role = 'Director'
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT d.director_name, ', ') WITHIN GROUP (ORDER BY d.director_name) AS directors
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        Directors d ON m.movie_id = d.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(i.keywords, 'No Keywords') AS keywords,
    COALESCE(i.directors, 'No Directors') AS directors
FROM 
    TopMovies t
LEFT JOIN 
    MovieInfo i ON t.movie_id = i.movie_id
ORDER BY 
    t.production_year DESC, t.title;
