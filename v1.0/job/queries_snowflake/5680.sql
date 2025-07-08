
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS actors,
        COUNT(c.id) AS cast_size
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        actors,
        cast_size,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_size DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    actors,
    cast_size
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, cast_size DESC;
