WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        an.name,
        ac.movie_count
    FROM 
        aka_name an
    JOIN 
        ActorMovieCounts ac ON an.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS actor_name,
    (SELECT COUNT(*) 
        FROM movie_info mi 
        WHERE mi.movie_id = rm.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info,
    (SELECT STRING_AGG(mk.keyword, ', ') 
        FROM movie_keyword mk 
        WHERE mk.movie_id = rm.movie_id) AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title;
