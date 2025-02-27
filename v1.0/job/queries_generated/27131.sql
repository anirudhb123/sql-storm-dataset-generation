WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        t.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type t ON m.kind_id = t.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        title_kind
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CastInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        c.nr_order
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
    tm.keyword,
    tm.title_kind,
    STRING_AGG(CONCAT(ci.actor_name, ' (', ci.actor_role, ')'), '; ') AS cast_list
FROM 
    TopMovies tm
LEFT JOIN 
    CastInfo ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.keyword, tm.title_kind
ORDER BY 
    tm.production_year DESC, tm.title;
