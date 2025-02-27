
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name, 
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT t.id) > 5
),
RecentMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id) AS info_count
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2010
)
SELECT 
    rm.title AS Movie_Title,
    rm.production_year AS Production_Year,
    rm.cast_count AS Cast_Count,
    pa.name AS Popular_Actor,
    rm2.info_count AS Info_Count
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON rm.cast_count = pa.movie_count
LEFT JOIN 
    RecentMovies rm2 ON rm.title = rm2.title
WHERE 
    rm.rank <= 10
    AND (rm.production_year IS NOT NULL OR rm2.info_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
