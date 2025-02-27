
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        t.kind_id
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    kc.keyword_count,
    kc.keywords,
    kt.kind
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordCounts kc ON rm.movie_id = kc.movie_id
LEFT JOIN 
    kind_type kt ON rm.kind_id = kt.id
WHERE 
    COALESCE(kc.keyword_count, 0) > 5
ORDER BY 
    rm.actor_count DESC, 
    kc.keyword_count DESC;
