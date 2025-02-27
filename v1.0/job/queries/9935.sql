WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    rc.role,
    co.name AS company_name,
    ((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id) + 
     (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id)) AS total_info
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rc ON ci.role_id = rc.id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
ORDER BY 
    tm.production_year DESC, 
    total_info DESC;
