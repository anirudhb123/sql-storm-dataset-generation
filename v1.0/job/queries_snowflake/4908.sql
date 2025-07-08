WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighRankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_per_year <= 5
),
MovieCollaborations AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT c.person_id) AS collaborator_count
    FROM 
        movie_companies m
    JOIN 
        movie_keyword k ON m.movie_id = k.movie_id
    JOIN 
        movie_info i ON m.movie_id = i.movie_id
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    hm.title, 
    COALESCE(mc.collaborator_count, 0) AS collaborators, 
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = hm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')) AS summary_count
FROM 
    HighRankedMovies hm
LEFT JOIN 
    MovieCollaborations mc ON hm.movie_id = mc.movie_id
WHERE 
    hm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    hm.production_year DESC, 
    collaborators DESC;
