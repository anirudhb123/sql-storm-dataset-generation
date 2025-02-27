WITH MovieCharacterNames AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order AS role_order,
        r.role AS character_role,
        p.info AS actor_info
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    WHERE 
        a.name IS NOT NULL
),
KeywordInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ki.keywords, 'No Keywords') AS keywords
    FROM 
        title m
    LEFT JOIN 
        KeywordInfo ki ON m.id = ki.movie_id
)
SELECT 
    mc.actor_name,
    mc.movie_title,
    mc.role_order,
    mc.character_role,
    md.production_year,
    md.keywords
FROM 
    MovieCharacterNames mc
JOIN 
    MovieDetails md ON mc.movie_title = md.title
ORDER BY 
    mc.actor_name, md.production_year DESC, mc.role_order;
