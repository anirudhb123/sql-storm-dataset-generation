WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        a.name AS main_actor, 
        COUNT(ci.id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),

KeywordCounts AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.main_actor,
    rm.num_cast_members,
    kc.keywords,
    kc.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordCounts kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast_members DESC;
