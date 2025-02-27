
WITH MovieTitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS comp_cast_type,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
),
TopGenreMovies AS (
    SELECT 
        title_id,
        title,
        COUNT(keyword) AS genre_count
    FROM 
        MovieTitleDetails
    GROUP BY 
        title_id, title
    ORDER BY 
        genre_count DESC
    LIMIT 10
)
SELECT 
    m.title,
    m.production_year,
    m.actors,
    g.genre_count
FROM 
    MovieTitleDetails m
JOIN 
    TopGenreMovies g ON m.title_id = g.title_id
ORDER BY 
    m.production_year DESC, g.genre_count DESC;
