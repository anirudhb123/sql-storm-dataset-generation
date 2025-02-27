WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actors,
    kc.keyword,
    ci.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, tm.title;
