WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
MovieDetails AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(DISTINCT a.actor_name, ', ') AS actors,
        MAX(m.rank) AS max_rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorMovies a ON m.movie_id = a.movie_id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        md.movie_id, 
        md.actors, 
        md.max_rank,
        CASE 
            WHEN md.max_rank IS NOT NULL THEN 'Ranked'
            ELSE 'Unranked'
        END AS rank_status
    FROM 
        MovieDetails md
    WHERE 
        md.actors IS NOT NULL
)
SELECT 
    fr.movie_id,
    fr.actors,
    fr.max_rank,
    fr.rank_status,
    CASE 
        WHEN fr.rank_status = 'Ranked' AND fr.max_rank < 5 THEN 'Top 5 Production Year'
        ELSE 'Other'
    END AS category
FROM 
    FinalResults fr
ORDER BY 
    fr.max_rank DESC, fr.movie_id;
