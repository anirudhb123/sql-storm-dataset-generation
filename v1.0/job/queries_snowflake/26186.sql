
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020 
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    k.keyword
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    tm.rank <= 10 
ORDER BY 
    tm.total_cast DESC;
