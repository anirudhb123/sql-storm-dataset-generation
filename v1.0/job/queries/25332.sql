WITH RankedMovies AS (
    SELECT 
        at.production_year,
        at.title,
        a.name AS actor_name,
        COUNT(ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') AND 
        a.name IS NOT NULL
    GROUP BY 
        at.id, at.production_year, at.title, a.name
),
TopMovies AS (
    SELECT 
        production_year,
        title,
        actor_name,
        total_actors,
        keywords,
        RANK() OVER (ORDER BY total_actors DESC) AS actor_rank
    FROM 
        RankedMovies
)
SELECT 
    tm.production_year,
    tm.title,
    tm.actor_name,
    tm.total_actors,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.actor_rank <= 10
ORDER BY 
    tm.production_year DESC, 
    total_actors DESC;
