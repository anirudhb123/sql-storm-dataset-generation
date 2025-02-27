WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithKeywords AS (
    SELECT 
        ak.person_id,
        ak.name,
        mk.keyword
    FROM 
        aka_name ak
    LEFT JOIN 
        movie_keyword mk ON ak.person_id = mk.movie_id
    WHERE 
        ak.name IS NOT NULL
),
KeywordCounts AS (
    SELECT 
        keyword,
        COUNT(*) AS count
    FROM 
        ActorsWithKeywords
    GROUP BY 
        keyword
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(kc.keyword, 'No Keywords') AS keyword,
    kc.count AS keyword_count,
    COUNT(DISTINCT ac.person_id) AS actor_count,
    MAX(COALESCE(cc.note, 'No note')) AS note
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.title_id = cc.movie_id
LEFT JOIN 
    cast_info ac ON cc.subject_id = ac.person_id
LEFT JOIN 
    KeywordCounts kc ON kc.keyword = 'Drama'
WHERE 
    rm.rank <= 3
GROUP BY 
    rm.title, rm.production_year, kc.keyword, kc.count
ORDER BY 
    rm.production_year DESC, actor_count DESC;
