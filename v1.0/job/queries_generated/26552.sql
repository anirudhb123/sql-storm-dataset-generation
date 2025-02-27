WITH RankedTitles AS (
    SELECT 
        at.title AS Movie_Title,
        at.production_year AS Production_Year,
        ak.name AS Actor_Name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS Actor_Rank,
        COUNT(DISTINCT ak.person_id) OVER (PARTITION BY at.id) AS Actor_Count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        Movie_Title,
        Production_Year,
        Actor_Name,
        Actor_Rank,
        Actor_Count
    FROM 
        RankedTitles 
    WHERE 
        Actor_Rank <= 3
),
AggregateTitles AS (
    SELECT 
        Production_Year,
        COUNT(DISTINCT Movie_Title) AS Title_Count,
        STRING_AGG(Actor_Name, ', ') AS Top_Actors
    FROM 
        FilteredTitles
    GROUP BY 
        Production_Year
)
SELECT 
    AT.Production_Year,
    AT.Title_Count,
    AT.Top_Actors,
    kt.kind AS Movie_Kind
FROM 
    AggregateTitles AT
JOIN 
    (SELECT DISTINCT 
         at.production_year, 
         kt.kind 
     FROM 
         aka_title at 
     JOIN 
         kind_type kt ON at.kind_id = kt.id) kt 
ON 
    AT.Production_Year = kt.production_year
ORDER BY 
    AT.Production_Year DESC, AT.Title_Count DESC;
