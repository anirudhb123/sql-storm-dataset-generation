WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ak.name AS actor_name,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, ak.name
),
TopMovies AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        tm.kind_id, 
        tm.actor_name, 
        tm.keyword_count
    FROM 
        RankedMovies tm
    WHERE 
        tm.rank = 1
)
SELECT 
    tm.title,
    tm.production_year,
    kt.kind,
    tm.actor_name,
    tm.keyword_count
FROM 
    TopMovies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.keyword_count DESC, 
    tm.production_year ASC
LIMIT 10;
