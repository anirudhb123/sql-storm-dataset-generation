WITH FilmKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS movie_keyword,
        k.phonetic_code
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        m.kind_id,
        mi.info AS movie_info
    FROM 
        aka_title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
)
SELECT 
    f.movie_title,
    f.movie_keyword,
    c.actor_name,
    c.role_type,
    m.production_year,
    m.movie_info
FROM 
    FilmKeywords f
JOIN 
    CastDetails c ON f.movie_title = c.movie_id
JOIN 
    MovieInfo m ON f.movie_title = m.title
WHERE 
    f.phonetic_code LIKE 'A%' 
    AND c.role_type IN ('Lead', 'Supporting')
ORDER BY 
    m.production_year DESC, 
    f.movie_title;
