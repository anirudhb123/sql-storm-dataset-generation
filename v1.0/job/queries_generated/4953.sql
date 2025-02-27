WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ai.info AS bio
    FROM 
        aka_name a
    LEFT JOIN 
        person_info ai ON a.person_id = ai.person_id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT ai.name, ', ') AS actors,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COALESCE(SUM(mi.note IS NOT NULL)::int, 0) AS info_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    ActorInfo ai ON ci.person_id = ai.actor_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, COUNT(DISTINCT ai.name) DESC;
