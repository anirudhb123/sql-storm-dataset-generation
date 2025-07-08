WITH RankedTitles AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) as movie_count
    FROM 
        cast_info c
    JOIN 
        RankedTitles rt ON c.movie_id = rt.title_id
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.id as actor_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    ORDER BY 
        amc.movie_count DESC
    LIMIT 10
)

SELECT 
    ta.name AS Actor_Name,
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    COUNT(DISTINCT c.id) AS Total_Cast_Count
FROM 
    TopActors ta
JOIN 
    cast_info c ON ta.actor_id = c.person_id
JOIN 
    RankedTitles rt ON c.movie_id = rt.title_id
GROUP BY 
    ta.name, rt.title, rt.production_year
ORDER BY 
    rt.production_year DESC, Total_Cast_Count DESC;
