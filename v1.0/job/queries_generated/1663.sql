WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.imdb_index) AS rank_by_year
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
),
MovieDetails AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        c.person_role_id,
        r.role AS character_role,
        a.name AS actor_name,
        COALESCE(a.name, 'Unknown Actor') AS display_name
    FROM 
        complete_cast c
    LEFT JOIN 
        title m ON c.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    COUNT(DISTINCT md.character_role) AS unique_roles,
    SUM(CASE WHEN md.actor_name IS NOT NULL THEN 1 ELSE 0 END) AS actor_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_count
FROM 
    MovieDetails md
WHERE 
    md.actor_name IS NOT NULL
GROUP BY 
    md.movie_title, md.production_year, md.actor_name
HAVING 
    COUNT(DISTINCT md.character_role) > 1
ORDER BY 
    md.production_year DESC, actor_count DESC
LIMIT 50;
