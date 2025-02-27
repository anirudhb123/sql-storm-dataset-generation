WITH MovieParticipation AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
), 
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        title,
        production_year
    FROM 
        MovieParticipation
    WHERE 
        movie_rank <= 5
), 
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    ta.actor_name,
    ta.title,
    ta.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN kc.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Keywords Available'
    END AS keyword_availability
FROM 
    TopActors ta
LEFT JOIN 
    KeywordCounts kc ON ta.movie_id = kc.movie_id
ORDER BY 
    ta.actor_name, ta.production_year DESC;
