
WITH MovieCast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COALESCE(MAX(m_info.info), 'No Info Available') AS movie_info,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actors,
        m.production_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info m_info ON m.id = m_info.movie_id AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, actors, actor_count, movie_info, rank_by_actors
    FROM 
        MovieCast
    WHERE 
        rank_by_actors <= 10
)
SELECT 
    t.title AS Movie_Title,
    tc.actors AS Actor_List,
    COALESCE(tc.movie_info, 'N/A') AS Movie_Info,
    NULLIF(tc.actor_count, 0) AS Total_Actors,
    CASE 
        WHEN tc.actor_count IS NULL THEN 'No Actors'
        WHEN tc.actor_count = 1 THEN 'Solo Star'
        ELSE 'Ensemble Cast'
    END AS Cast_Type
FROM 
    TopMovies tc
JOIN 
    aka_title t ON tc.movie_id = t.id
ORDER BY 
    tc.actor_count DESC, t.title;
