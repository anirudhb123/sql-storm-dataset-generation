WITH MovieKeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
ActorMovieCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        COALESCE(amc.actor_count, 0) AS actor_count
    FROM 
        title m
    LEFT JOIN 
        MovieKeywordCounts mkc ON m.id = mkc.movie_id
    LEFT JOIN 
        ActorMovieCounts amc ON m.id = amc.movie_id
    WHERE 
        m.production_year > 2000
    ORDER BY 
        mkc.keyword_count DESC, amc.actor_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    tm.keyword_count DESC, tm.actor_count DESC;
