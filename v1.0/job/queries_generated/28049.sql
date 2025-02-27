WITH 
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
    HAVING 
        COUNT(c.id) > 1
),

RecentMoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_id,
        mi.info AS movie_info
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year >= 2020
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.imdb_id,
    r.movie_info,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(ta.actor_count, 0) AS actor_count
FROM 
    RecentMoviesWithInfo r
LEFT JOIN 
    MovieKeywordCounts mkc ON r.movie_id = mkc.movie_id
LEFT JOIN 
    TopActors ta ON r.movie_id = ta.movie_id
WHERE 
    r.movie_info IS NOT NULL
ORDER BY 
    r.production_year DESC, 
    keyword_count DESC, 
    actor_count DESC
LIMIT 50;
