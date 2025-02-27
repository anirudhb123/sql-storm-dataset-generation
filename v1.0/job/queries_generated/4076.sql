WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY a.id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
Actors AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ak.id) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_year,
    COALESCE(a.actor_count, 0) AS total_actors,
    rm.company_count,
    CASE 
        WHEN rm.company_count > 5 THEN 'High Production'
        WHEN rm.company_count BETWEEN 3 AND 5 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_level
FROM 
    RankedMovies rm
LEFT JOIN 
    Actors a ON rm.movie_id = a.movie_id
WHERE 
    (rm.rank_year <= 10 AND rm.company_count > 0) OR 
    (rm.rank_year > 10 AND rm.production_year BETWEEN 2000 AND 2010)
ORDER BY 
    rm.production_year DESC,
    rm.company_count DESC
LIMIT 50;

WITH MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords
FROM 
    aka_title m
LEFT JOIN 
    MovieKeywords mk ON m.id = mk.movie_id
WHERE 
    m.production_year IS NOT NULL
ORDER BY 
    m.production_year DESC;
