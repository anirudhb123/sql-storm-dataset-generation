WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast, 
        actors 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id) AS info_count,
    (SELECT STRING_AGG(kw.keyword, ', ') FROM movie_keyword mk JOIN keyword kw ON mk.keyword_id = kw.id WHERE mk.movie_id = tm.movie_id) AS keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
