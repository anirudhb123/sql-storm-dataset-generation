WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE
        m.production_year IS NOT NULL
        AND m.title IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year, 
        ac.actor_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorCounts ac ON r.movie_id = ac.movie_id
    WHERE 
        r.rank <= 5
)
SELECT 
    fm.title AS MovieTitle,
    fm.production_year AS ProductionYear,
    COALESCE(fm.actor_count, 0) AS NumberOfActors,
    (SELECT COUNT(*) 
     FROM aka_name an 
     JOIN cast_info ci ON an.person_id = ci.person_id 
     WHERE ci.movie_id = fm.movie_id 
       AND an.name IS NOT NULL) AS NamedActorCount,
    (SELECT STRING_AGG(DISTINCT an.name, ', ') 
     FROM aka_name an 
     WHERE an.person_id IN (SELECT ci.person_id 
                            FROM cast_info ci 
                            WHERE ci.movie_id = fm.movie_id AND ci.note IS NOT NULL)) AS NotedActorNames
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description') 
    OR mi.info_type_id IS NULL
ORDER BY 
    fm.production_year DESC,
    fm.title ASC
LIMIT 10;