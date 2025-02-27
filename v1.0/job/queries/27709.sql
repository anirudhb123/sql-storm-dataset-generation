WITH RankedMovies AS (
    SELECT 
        k.keyword AS movie_keyword,
        a.title AS movie_title,
        t.production_year,
        COUNT(ci.id) AS total_cast_members
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        title t ON a.id = t.id
    GROUP BY 
        k.keyword, a.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_keyword,
        movie_title,
        production_year,
        total_cast_members,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast_members DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_keyword,
    tm.movie_title,
    tm.production_year,
    tm.total_cast_members
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast_members DESC;
