WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
),
CharacterNames AS (
    SELECT 
        cn.name,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_as
    FROM 
        char_name cn
    LEFT JOIN 
        aka_name ak ON ak.person_id = cn.imdb_id
    GROUP BY 
        cn.name
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    cn.name AS character_name,
    cn.known_as,
    CASE 
        WHEN md.actor_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    MovieDetails md
LEFT JOIN 
    CharacterNames cn ON md.movie_id = (SELECT movie_id FROM cast_info ci WHERE ci.person_id = (SELECT person_id FROM name n WHERE n.name = cn.name LIMIT 1))
WHERE 
    md.actor_count IS NOT NULL
ORDER BY 
    md.production_year DESC, md.actor_count DESC
LIMIT 100;
