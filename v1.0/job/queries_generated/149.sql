WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_count,
        actors,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    t.title,
    t.production_year,
    t.actor_count,
    t.actors,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    COALESCE(mk.id, -1) AS keyword_id
FROM 
    TopMovies t
LEFT JOIN 
    movie_keyword mk ON t.title_id = mk.movie_id
WHERE 
    t.rn <= 10
ORDER BY 
    t.actor_count DESC, t.production_year DESC;
