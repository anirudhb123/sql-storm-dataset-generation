
WITH MovieRoles AS (
    SELECT 
        ct.role AS role_type, 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type ct ON ci.role_id = ct.id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ct.role, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MovieRoles
),
KeywordMovies AS (
    SELECT 
        t.title AS movie_title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    LISTAGG(km.keyword, ', ') WITHIN GROUP (ORDER BY km.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordMovies km ON tm.movie_title = km.movie_title
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_title, tm.production_year, tm.actor_count
ORDER BY 
    tm.actor_count DESC;
