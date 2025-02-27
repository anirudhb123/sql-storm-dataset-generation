WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
HighActorCount AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
),
RelatedMovies AS (
    SELECT 
        m.title AS related_title,
        m.production_year AS related_year,
        COUNT(l.linked_movie_id) AS link_count
    FROM 
        movie_link l
    JOIN 
        title m ON l.linked_movie_id = m.id
    INNER JOIN 
        HighActorCount h ON m.production_year = h.production_year
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    hm.title AS main_title,
    hm.production_year,
    hm.actor_count,
    COALESCE(rm.related_title, 'No Related Movies') AS related_movie,
    COALESCE(rm.link_count, 0) AS related_movie_count
FROM 
    HighActorCount hm
LEFT JOIN 
    RelatedMovies rm ON hm.production_year = rm.related_year
ORDER BY 
    hm.production_year DESC, 
    hm.actor_count DESC;
