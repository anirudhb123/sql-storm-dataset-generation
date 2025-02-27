WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS actor_count, 
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id 
    JOIN 
        cast_info ci ON cc.subject_id = ci.id 
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id 
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.actor_count, 
    tm.cast_names,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, tm.cast_names
ORDER BY 
    tm.actor_count DESC;
