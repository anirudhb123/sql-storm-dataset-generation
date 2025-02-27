WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.role_id::TEXT, ', ') AS role_ids,
        COUNT(DISTINCT ka.person_id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, company_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.actor_count,
    k.keyword
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, tm.company_count DESC;
