WITH RatedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT m3.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.id
),

PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        company_count,
        year_rank
    FROM 
        RatedMovies
    WHERE 
        year_rank <= 5
)

SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.actor_names,
    CASE 
        WHEN pm.company_count IS NULL THEN 'No Companies' 
        ELSE CONCAT(pm.company_count, ' Companies Involved') 
    END AS company_status
FROM 
    PopularMovies pm
WHERE 
    pm.production_year > 2000
UNION ALL
SELECT 
    t.title,
    t.production_year,
    COUNT(ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    'Archived Production' AS company_status
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    NOT EXISTS (
        SELECT 1 FROM RatedMovies rm WHERE rm.movie_id = t.id
    )
    AND t.production_year <= 2000
GROUP BY 
    t.id;

-- This query retrieves popular movies produced after the year 2000 with up to 5 entries for each production year,
-- ranks them by the number of cast members, also lists the company involvement,
-- and uses a UNION ALL to append archived productions (those not appearing in the popular list) produced up to 2000.

