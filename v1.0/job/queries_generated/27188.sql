WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.person_role_id) AS role_count
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_name,
        role_count,
        RANK() OVER (PARTITION BY production_year ORDER BY role_count DESC) AS rank
    FROM 
        RankedMovies
),
SelectedMovies AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        tm.actor_name
    FROM 
        TopMovies tm
    WHERE 
        tm.rank <= 5
)
SELECT 
    sm.title AS Movie_Title,
    sm.production_year AS Production_Year,
    sm.actor_name AS Leading_Actor,
    JSON_AGG(DISTINCT kc.keyword) AS Keywords
FROM 
    SelectedMovies sm
JOIN 
    movie_keyword mk ON sm.title_id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    sm.title, sm.production_year, sm.actor_name
ORDER BY 
    sm.production_year DESC, COUNT(kc.keyword) DESC;
