
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS an ON c.person_id = an.person_id
    LEFT JOIN 
        movie_keyword AS mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        actors,
        keywords,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    total_cast,
    actors,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, total_cast DESC;
