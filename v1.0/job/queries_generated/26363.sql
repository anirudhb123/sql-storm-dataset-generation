WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY LENGTH(t.title) DESC) AS rank_by_title_length
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.keyword 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_title_length = 1
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.info AS actor_info
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
)
SELECT 
    fm.title,
    fm.production_year,
    STRING_AGG(DISTINCT am.actor_name, ', ') AS actor_list,
    STRING_AGG(DISTINCT am.actor_info, ', ') AS actor_birthdates
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorMovies am ON fm.movie_id = am.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year
ORDER BY 
    fm.production_year DESC;
