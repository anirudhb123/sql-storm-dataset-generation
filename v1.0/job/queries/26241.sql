
WITH MovieCast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        a.name AS actor_name,
        c.nr_order AS actor_order,
        COALESCE(p.info, 'No info available') AS actor_info
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id AND p.info_type_id = 1 
    WHERE 
        m.production_year >= 2000
        AND a.name LIKE 'A%'
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        c.movie_id,
        c.movie_title,
        c.actor_name,
        c.actor_order,
        c.actor_info,
        COALESCE(ki.keywords, 'No keywords') AS keywords
    FROM 
        MovieCast c
    LEFT JOIN 
        KeywordInfo ki ON c.movie_id = ki.movie_id
)
SELECT 
    md.movie_title,
    STRING_AGG(DISTINCT md.actor_name || ' (' || md.actor_order || ')', ', ') AS actors,
    md.keywords
FROM 
    MovieDetails md
GROUP BY 
    md.movie_title, md.keywords
ORDER BY 
    md.movie_title;
