WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id ASC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COALESCE(SUM(mi.info_length), 0) AS total_info_length,
        COUNT(DISTINCT ki.keyword) AS total_keywords
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN (
        SELECT 
            mi.movie_id,
            LENGTH(mi.info) AS info_length
        FROM 
            movie_info mi
        WHERE 
            mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%biography%')
    ) mi ON c.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        c.person_id, a.name
),
RecentMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    ai.actor_name,
    ARRAY_AGG(DISTINCT rm.title) AS recent_titles,
    ai.total_info_length AS biography_length,
    ai.total_keywords
FROM 
    ActorInfo ai
JOIN 
    cast_info ci ON ai.person_id = ci.person_id
JOIN 
    RecentMovies rm ON ci.movie_id = rm.movie_id
GROUP BY 
    ai.actor_name, ai.total_info_length, ai.total_keywords
HAVING 
    COUNT(DISTINCT rm.movie_id) > 1 AND 
    ai.total_keywords < (SELECT AVG(total_keywords) FROM ActorInfo)
ORDER BY 
    ai.actor_name;
