WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CoActors AS (
    SELECT 
        c1.movie_id,
        COUNT(DISTINCT c2.person_id) AS co_actor_count
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
    GROUP BY 
        c1.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ca.co_actor_count, 0) AS co_actor_count,
        rm.rank,
        CASE 
            WHEN ca.co_actor_count IS NULL THEN 'No Co-actors'
            WHEN ca.co_actor_count > 5 THEN 'High Co-actor Count'
            ELSE 'Moderate Co-actor Count'
        END AS co_actor_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CoActors ca ON rm.movie_id = ca.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.co_actor_count,
    md.co_actor_status
FROM 
    MovieDetails md
WHERE 
    md.rank <= 10
ORDER BY 
    md.production_year DESC, md.co_actor_count DESC
LIMIT 20;
