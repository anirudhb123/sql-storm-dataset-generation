WITH MoviePerformances AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        m.production_year,
        r.role AS character_name,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COALESCE(COUNT(*) FILTER (WHERE c.note IS NOT NULL), 0) AS notes_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND a.name IS NOT NULL
    GROUP BY 
        a.name, t.title, m.production_year, r.role
),
RankedPerformances AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        character_name,
        keywords,
        notes_count,
        RANK() OVER (PARTITION BY actor_name ORDER BY production_year DESC, notes_count DESC) AS performance_rank
    FROM 
        MoviePerformances
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    character_name,
    keywords,
    notes_count,
    performance_rank
FROM 
    RankedPerformances
WHERE 
    performance_rank <= 5
ORDER BY 
    actor_name, production_year DESC;

This SQL query retrieves the top five performances for each actor from movies released between 2000 and 2023, taking into account the role played, the associated keywords, and any notes available. The results are ranked based on the movie's production year and the number of notes, providing a comprehensive overview of notable performances in a specified timeframe.
