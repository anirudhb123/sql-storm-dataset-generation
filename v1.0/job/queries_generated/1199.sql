WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5
),
ActorInfo AS (
    SELECT 
        a.person_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        a.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    ai.actor_names,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id IN (
        SELECT id FROM info_type WHERE info IN ('Budget', 'Box Office')
    )
LEFT JOIN 
    ActorInfo ai ON ai.person_id IN (
        SELECT DISTINCT c.person_id
        FROM cast_info c
        JOIN complete_cast cc ON c.movie_id = cc.movie_id
        WHERE cc.movie_id = tm.movie_id
    )
ORDER BY 
    tm.production_year DESC, 
    tm.title;
