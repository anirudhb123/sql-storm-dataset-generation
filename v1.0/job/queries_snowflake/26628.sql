
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.movie_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    tm.title,
    tm.production_year,
    cd.actor_name,
    COUNT(cd.actor_name) AS actor_count,
    LISTAGG(cd.actor_name, ', ') WITHIN GROUP (ORDER BY cd.actor_name) AS actor_list
FROM 
    TopMovies tm
JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
GROUP BY 
    tm.title, tm.production_year, cd.actor_name
ORDER BY 
    tm.production_year DESC, actor_count DESC;
