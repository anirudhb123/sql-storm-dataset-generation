WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_position,
        CASE 
            WHEN t.production_year > 2000 THEN 'Modern' 
            WHEN t.production_year < 1950 THEN 'Classic' 
            ELSE 'Mid-Century' 
        END AS era
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_title,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS actor_count,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) OVER (PARTITION BY c.movie_id) AS null_notes_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 
MovieWithRoles AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        d.actor_name,
        d.role_title,
        d.actor_count,
        d.null_notes_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY d.actor_count DESC) AS rank
    FROM 
        RecursiveMovieCTE m
    LEFT JOIN 
        CastDetails d ON m.movie_id = d.movie_id
), 
RankingByEra AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name,
        role_title,
        actor_count,
        null_notes_count,
        rank,
        era,
        LAG(actor_count, 1, 0) OVER (PARTITION BY era ORDER BY actor_count DESC) AS previous_actor_count
    FROM 
        MovieWithRoles
)

SELECT 
    r.title,
    r.production_year,
    r.actor_name,
    r.role_title,
    r.actor_count,
    r.null_notes_count,
    r.rank,
    r.era,
    CASE 
        WHEN r.actor_count > r.previous_actor_count THEN 'Increased'
        WHEN r.actor_count < r.previous_actor_count THEN 'Decreased'
        ELSE 'No Change'
    END AS actor_count_trend
FROM 
    RankingByEra r
WHERE 
    r.actor_count IS NOT NULL
ORDER BY 
    r.production_year DESC,
    r.rank;
