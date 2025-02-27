WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    ak.name AS actor_name,
    kt.keyword AS keyword
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
JOIN 
    keyword kt ON kt.id = mk.keyword_id
JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;
