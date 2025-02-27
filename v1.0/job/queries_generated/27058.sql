WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_info_length,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),

PopularActors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movies_played,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    a.name AS actor_name,
    a.movies_played,
    a.movie_titles,
    m.company_count,
    m.avg_info_length
FROM 
    RankedMovies m
JOIN 
    PopularActors a ON m.production_year = (
        SELECT MAX(production_year) FROM RankedMovies
    )
WHERE 
    m.rank <= 5
ORDER BY 
    m.company_count DESC, 
    m.avg_info_length DESC;
