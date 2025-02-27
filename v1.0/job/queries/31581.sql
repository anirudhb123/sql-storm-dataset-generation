WITH RECURSIVE ActorHierarchy AS (
    
    SELECT 
        ci.person_id, 
        t.title, 
        t.production_year,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year = 2020

    UNION ALL

    
    SELECT 
        ci.person_id, 
        t.title, 
        t.production_year,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ci ON ah.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year < 2020  
),
ActorMovies AS (
    SELECT 
        ah.person_id,
        COUNT(DISTINCT ah.title) AS movie_count,
        MAX(ah.production_year) AS last_movie_year,
        STRING_AGG(DISTINCT ah.title, ', ') AS movie_titles
    FROM 
        ActorHierarchy ah
    GROUP BY 
        ah.person_id
),
RankedActors AS (
    SELECT 
        am.person_id, 
        am.movie_count, 
        am.last_movie_year,
        am.movie_titles,
        ROW_NUMBER() OVER (ORDER BY am.movie_count DESC) as rank
    FROM 
        ActorMovies am
    WHERE 
        am.movie_count > 0  
)
SELECT 
    ak.name AS actor_name,
    ra.movie_count,
    ra.last_movie_year,
    ra.movie_titles,
    COALESCE(ca.kind, 'Unknown') AS company_type
FROM 
    RankedActors ra
JOIN 
    aka_name ak ON ra.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON ra.person_id = mc.movie_id  
LEFT JOIN 
    company_type ca ON mc.company_type_id = ca.id 
WHERE 
    ra.rank <= 10  
ORDER BY 
    ra.movie_count DESC;