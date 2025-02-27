WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT tt.title, ', ') AS titles,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        RankedMovies tt ON tt.movie_id = c.movie_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        person_id,
        movie_count,
        titles,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorStats
    WHERE 
        movie_count > 5
)
SELECT 
    a.name,
    ta.movie_count,
    ta.titles,
    ta.rank
FROM 
    TopActors ta
JOIN 
    aka_name a ON a.person_id = ta.person_id
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.rank;
