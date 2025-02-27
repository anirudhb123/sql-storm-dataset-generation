
WITH ActorMovieCounts AS (
    SELECT 
        a.id AS actor_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN mkc.keyword_count > 0 THEN 'Has Keywords'
            ELSE 'No Keywords'
        END AS keyword_status
    FROM 
        title m
    LEFT JOIN 
        MovieKeywordCounts mkc ON m.id = mkc.movie_id
    WHERE 
        m.production_year >= 2000
),
RankedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.keyword_count,
        fm.keyword_status,
        RANK() OVER (PARTITION BY fm.keyword_status ORDER BY fm.keyword_count DESC) AS rank
    FROM 
        FilteredMovies fm
)
SELECT 
    ram.actor_id,
    r.movie_id,
    r.title,
    r.keyword_count,
    r.keyword_status
FROM 
    ActorMovieCounts ram
JOIN 
    cast_info ci ON ram.actor_id = ci.person_id
JOIN 
    RankedMovies r ON ci.movie_id = r.movie_id
WHERE 
    r.rank <= 10
AND 
    (r.keyword_status = 'Has Keywords' OR r.keyword_count IS NULL)
ORDER BY 
    ram.actor_id, r.keyword_count DESC;
