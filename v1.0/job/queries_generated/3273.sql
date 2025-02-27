WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCount amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 10
)
SELECT 
    rm.title,
    rm.production_year,
    ta.name AS actor_name,
    COALESCE(mci.note, 'No Info') AS movie_note,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = t.id) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.title = cc.movie_id
LEFT JOIN 
    TopActors ta ON cc.subject_id = ta.id
LEFT JOIN 
    movie_info mi ON rm.production_year = mi.movie_id
LEFT JOIN 
    movie_info_idx mci ON rm.production_year = mci.movie_id
WHERE 
    rm.movie_rank <= 5
    AND (ta.name IS NOT NULL OR rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, 
    keyword_count DESC;
