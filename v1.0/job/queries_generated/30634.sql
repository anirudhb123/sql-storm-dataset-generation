WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        ci.person_id
),
MovieAwards AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT mt.info ORDER BY mt.info_type_id) AS awards
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%award%'
    GROUP BY 
        mc.movie_id
),
TitlesWithAwardCounts AS (
    SELECT 
        t.title,
        COUNT(DISTINCT mw.movie_id) AS award_count
    FROM 
        title t
    LEFT JOIN 
        MovieAwards mw ON t.id = mw.movie_id
    GROUP BY 
        t.title
)
SELECT 
    an.name AS actor_name,
    ah.movie_count,
    t.title,
    twc.award_count
FROM 
    ActorHierarchy ah
JOIN 
    aka_name an ON ah.person_id = an.person_id
LEFT JOIN 
    cast_info ci ON ci.person_id = an.person_id
LEFT JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    TitlesWithAwardCounts twc ON t.title = twc.title
WHERE 
    ah.movie_count > 5
ORDER BY 
    ah.movie_count DESC, twc.award_count DESC
LIMIT 20;
