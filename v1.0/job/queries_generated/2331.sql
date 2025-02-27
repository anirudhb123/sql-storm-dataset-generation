WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast_count = 1
),
MovieInfo AS (
    SELECT 
        m.title,
        mi.info AS genre_info,
        mi.note AS genre_note
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
),
CompleteInfo AS (
    SELECT 
        h.title,
        h.production_year,
        COALESCE(gi.genre_info, 'Unknown Genre') AS genre_info,
        COALESCE(gi.genre_note, 'No Notes Available') AS genre_note
    FROM 
        HighCastMovies h
    LEFT JOIN 
        MovieInfo gi ON h.title = gi.title
)
SELECT 
    ci.name AS actor_name,
    ci.note AS actor_note,
    c.title AS movie_title,
    c.production_year,
    c.genre_info,
    c.genre_note
FROM 
    cast_info ci
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    CompleteInfo c ON cc.movie_id = c.title
WHERE 
    ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Lead')
ORDER BY 
    c.production_year DESC, ci.name;
