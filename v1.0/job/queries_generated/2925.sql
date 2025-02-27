WITH ActorMovies AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    GROUP BY 
        c.person_id, a.name
),
ActorAwards AS (
    SELECT 
        person_id, 
        COUNT(*) AS award_count 
    FROM 
        person_info p
    WHERE 
        EXISTS (SELECT 1 FROM info_type it WHERE it.id = p.info_type_id AND it.info = 'Award')
    GROUP BY 
        person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    a.actor_name,
    COALESCE(am.movie_count, 0) AS total_movies,
    COALESCE(aa.award_count, 0) AS total_awards,
    mwk.keywords
FROM 
    ActorMovies am
LEFT JOIN 
    ActorAwards aa ON am.person_id = aa.person_id
JOIN 
    MoviesWithKeywords mwk ON mwk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = am.person_id)
WHERE 
    total_movies > 5
ORDER BY 
    total_movies DESC, 
    actor_name ASC;
