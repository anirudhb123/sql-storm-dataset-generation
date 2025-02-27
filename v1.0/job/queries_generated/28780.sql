WITH RankedTitles AS (
    SELECT 
        at.title AS MovieTitle,
        at.production_year AS ProductionYear,
        ak.name AS ActorName,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS ActorRank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
        AND ak.name IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ak.name AS ActorName,
        COUNT(DISTINCT ci.movie_id) AS RoleCount
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
TopActors AS (
    SELECT 
        ActorName,
        RoleCount,
        RANK() OVER (ORDER BY RoleCount DESC) AS ActorRank
    FROM 
        ActorRoleCounts
    WHERE 
        RoleCount > 5
)
SELECT 
    rt.MovieTitle,
    rt.ProductionYear,
    rt.ActorName,
    tal.RoleCount AS TotalRoles,
    rt.ActorRank
FROM 
    RankedTitles rt
JOIN 
    TopActors tal ON rt.ActorName = tal.ActorName
WHERE 
    rt.ActorRank <= 3
ORDER BY 
    rt.ProductionYear DESC,
    rt.MovieTitle;
