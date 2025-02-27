WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keyword, 
        num_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id) AS info_count,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id) AS company_count
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.num_cast DESC;
