WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(cc.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(cc.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    GROUP BY 
        ak.id, ak.name
),
RecentMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        cast_info cc ON t.id = cc.movie_id
    JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    WHERE 
        t.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    pa.actor_name,
    pa.movie_count,
    CASE 
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        WHEN rm.cast_count IS NULL THEN 'Unknown Cast'
        ELSE 'Small Cast'
    END AS cast_size_desc
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON rm.rank = pa.actor_rank
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
