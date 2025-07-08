
WITH RankedMovies AS (
    SELECT 
        mt.title AS Movie_Title,
        mt.production_year AS Production_Year,
        ak.name AS Actor_Name,
        ak.imdb_index AS Actor_IMDB_Index,
        mp.name AS Production_Company,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS Actor_Rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        company_name mp ON mc.company_id = mp.id
    WHERE 
        mt.production_year >= 2000
),
ActorStats AS (
    SELECT 
        Actor_Name,
        COUNT(DISTINCT Movie_Title) AS Total_Movies,
        COUNT(DISTINCT Production_Year) AS Active_Years
    FROM 
        RankedMovies
    WHERE 
        Actor_Rank <= 3
    GROUP BY 
        Actor_Name
),
TopActors AS (
    SELECT 
        Actor_Name,
        Total_Movies,
        Active_Years,
        RANK() OVER (ORDER BY Total_Movies DESC) AS Actor_Rank
    FROM 
        ActorStats
)
SELECT 
    ta.Actor_Name,
    ta.Total_Movies,
    ta.Active_Years,
    k.keyword AS Popular_Keyword,
    LISTAGG(DISTINCT mt.title, ', ') WITHIN GROUP (ORDER BY mt.title) AS Movies
FROM 
    TopActors ta
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT ci.movie_id FROM cast_info ci JOIN aka_name ak ON ak.person_id = ci.person_id WHERE ak.name = ta.Actor_Name)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title mt ON mt.id = mk.movie_id
WHERE 
    ta.Actor_Rank <= 10
GROUP BY 
    ta.Actor_Name, ta.Total_Movies, ta.Active_Years, k.keyword
ORDER BY 
    ta.Total_Movies DESC;
