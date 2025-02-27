WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
CoActors AS (
    SELECT 
        c1.movie_id,
        c1.person_id AS actor_1,
        c2.person_id AS actor_2
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    kc.keyword_count,
    COUNT(DISTINCT ca.actor_2) AS co_actor_count
FROM 
    RankedMovies m
LEFT JOIN 
    KeywordCounts kc ON m.id = kc.movie_id
LEFT JOIN 
    CoActors ca ON m.id = ca.movie_id
WHERE 
    m.year_rank <= 5
GROUP BY 
    m.title, m.production_year, m.cast_count, kc.keyword_count
HAVING 
    COALESCE(kc.keyword_count, 0) > 0 AND 
    COUNT(DISTINCT ca.actor_2) > 1
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
