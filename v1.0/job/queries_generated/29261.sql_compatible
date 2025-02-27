
WITH ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT at.movie_id) AS movie_count,
        STRING_AGG(DISTINCT at.title, ', ') AS titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    GROUP BY 
        a.id, a.name
), 
PerformanceData AS (
    SELECT 
        at.actor_id,
        at.actor_name,
        at.movie_count,
        pd.production_year,
        COUNT(DISTINCT pd.id) AS performances
    FROM 
        ActorTitles at
    JOIN 
        complete_cast cc ON at.actor_id = cc.subject_id
    JOIN 
        title pd ON cc.movie_id = pd.id
    WHERE 
        pd.production_year > 2000
    GROUP BY 
        at.actor_id, at.actor_name, at.movie_count, pd.production_year
), 
ActorRanking AS (
    SELECT 
        actor_id,
        actor_name,
        SUM(performances) AS total_performances
    FROM 
        PerformanceData
    GROUP BY 
        actor_id, actor_name
    ORDER BY 
        total_performances DESC
)
SELECT 
    ar.actor_id,
    ar.actor_name,
    ar.total_performances,
    at.titles
FROM 
    ActorRanking ar
LEFT JOIN 
    ActorTitles at ON ar.actor_id = at.actor_id
LIMIT 10;
