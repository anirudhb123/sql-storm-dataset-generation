WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), TitleCount AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count
    FROM 
        RankedTitles
    GROUP BY 
        production_year
), ActorCount AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
)
SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    tc.movie_count,
    ac.movies_count
FROM 
    RankedTitles r
JOIN 
    TitleCount tc ON r.production_year = tc.production_year
JOIN 
    ActorCount ac ON r.actor_name = ac.actor_name
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.actor_name;
