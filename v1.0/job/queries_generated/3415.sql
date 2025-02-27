WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        l.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MIN(t.production_year) AS earliest_year,
        SUM(CASE WHEN m.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title l
    JOIN 
        complete_cast c ON l.id = c.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = l.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON l.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info m ON l.id = m.movie_id
    GROUP BY 
        l.movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 2
)
SELECT 
    m.movie_id,
    m.actor_names,
    m.earliest_year,
    m.note_count,
    m.keyword_count,
    pm.actor_name,
    pm.movie_count
FROM 
    MovieDetails m
JOIN 
    PopularActors pm ON pm.movie_count > m.keyword_count
WHERE 
    m.earliest_year > 2000
ORDER BY 
    m.note_count DESC, 
    m.keyword_count DESC
LIMIT 100;
