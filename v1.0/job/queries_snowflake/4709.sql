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
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    WHERE 
        mc.company_type_id IN (
            SELECT 
                id 
            FROM 
                company_type 
            WHERE 
                kind LIKE 'Production%'
        )
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 5
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    pa.name AS popular_actor,
    pa.movie_count
FROM 
    RankedMovies rm
FULL OUTER JOIN 
    PopularActors pa ON rm.rank = 1
WHERE 
    rm.production_year BETWEEN 2000 AND 2020 
    AND (pa.movie_count IS NULL OR pa.movie_count > 10)
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
