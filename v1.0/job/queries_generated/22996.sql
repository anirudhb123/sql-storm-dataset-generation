WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.id, t.title, t.production_year
), 
ComplicatedPredicates AS (
    SELECT 
        r.*,
        CASE 
            WHEN actor_count IS NULL THEN 'No Actors'
            WHEN actor_count > 10 THEN 'Blockbuster'
            ELSE 'Indie Film' 
        END AS movie_type
    FROM 
        RankedMovies r
    WHERE 
        (rn <= 5 AND production_year >= 2000) OR 
        (production_year < 2000 AND actor_count IS NOT NULL AND actor_count < 5)
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    cp.title,
    cp.production_year,
    cp.actor_count,
    cp.movie_type,
    k.keyword_count,
    COALESCE(NULLIF(cp.actor_count, 0), 'No Data') AS actor_count_description
FROM 
    ComplicatedPredicates cp
LEFT JOIN 
    KeywordCounts k ON cp.aka_id = k.movie_id
WHERE 
    k.keyword_count IS NOT NULL OR cp.movie_type = 'Blockbuster'
ORDER BY 
    cp.production_year DESC,
    cp.actor_count DESC
FETCH FIRST 10 ROWS ONLY;


