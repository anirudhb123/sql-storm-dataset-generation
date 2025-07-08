
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.movie_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    a.name AS actor_name,
    tm.title AS movie_title,
    tm.production_year,
    LISTAGG(tk.keyword, ', ') WITHIN GROUP (ORDER BY tk.keyword) AS keywords,
    COUNT(ci.movie_id) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    TopMovies tm ON ci.movie_id = tm.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword tk ON mk.keyword_id = tk.id
GROUP BY 
    a.name, tm.title, tm.production_year
ORDER BY 
    total_roles DESC, a.name;
