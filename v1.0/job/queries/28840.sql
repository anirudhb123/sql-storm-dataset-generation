
WITH MovieInfo AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender AS actor_gender,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.title, t.production_year, a.name, p.gender
    ORDER BY 
        t.production_year DESC
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_gender,
    keywords,
    LENGTH(movie_title) AS title_length,
    LENGTH(actor_name) AS actor_length
FROM 
    MovieInfo
WHERE 
    actor_gender = 'F'
    AND LENGTH(movie_title) > 20
    AND (SELECT COUNT(*) FROM MovieInfo AS sub WHERE movie_title = sub.movie_title) > 1
ORDER BY 
    title_length DESC;
