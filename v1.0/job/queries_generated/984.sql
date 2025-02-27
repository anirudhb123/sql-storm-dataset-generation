WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
MovieKeywordCounts AS (
    SELECT 
        m.id AS movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        m.title, 
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY k.keyword_count DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        MovieKeywordCounts k ON m.id = k.movie_id
    WHERE 
        m.production_year IS NOT NULL
)
SELECT 
    a.actor_name,
    tm.title,
    tm.production_year,
    COALESCE(mkc.keyword_count, 0) AS total_keywords,
    RANK() OVER (PARTITION BY tm.production_year ORDER BY COALESCE(mkc.keyword_count, 0) DESC) AS keyword_rank
FROM 
    ActorMovies a
JOIN 
    complete_cast c ON a.actor_id = c.subject_id
JOIN 
    aka_title tm ON c.movie_id = tm.id
LEFT JOIN 
    MovieKeywordCounts mkc ON tm.id = mkc.movie_id
WHERE 
    a.movie_count > 5
ORDER BY 
    tm.production_year DESC, keyword_rank ASC;
