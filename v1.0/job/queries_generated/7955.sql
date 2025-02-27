WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT a.id) AS actor_count,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        keyword_count,
        RANK() OVER (ORDER BY actor_count DESC, keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.keyword_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, tm.keyword_count DESC;
