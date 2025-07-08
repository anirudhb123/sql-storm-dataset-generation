
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        m.title,
        m.production_year,
        m.actor_count
    FROM 
        RankedMovies m
    JOIN 
        cast_info ci ON m.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        m.rank <= 5
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    d.actor_name,
    d.title,
    d.production_year,
    COALESCE(ARRAY_TO_STRING(g.genres, ', '), 'No Genres') AS genres
FROM 
    ActorDetails d
LEFT JOIN 
    MovieGenres g ON d.title = (SELECT title FROM aka_title WHERE id = g.movie_id)
WHERE 
    d.actor_count > 0
ORDER BY 
    d.production_year DESC, d.actor_name;
