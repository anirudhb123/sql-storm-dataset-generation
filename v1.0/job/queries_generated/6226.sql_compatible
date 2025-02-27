
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.title, 
        t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        actor_names,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.actor_count, 
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
