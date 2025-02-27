WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),

SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_keyword,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 5
),

PersonMovies AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        sm.movie_id,
        sm.title
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        SelectedMovies sm ON ci.movie_id = sm.movie_id
)

SELECT 
    pm.actor_name,
    sm.title,
    sm.production_year,
    STRING_AGG(pm.actor_name, ', ') OVER (PARTITION BY sm.movie_id) AS all_actors
FROM 
    PersonMovies pm
JOIN 
    SelectedMovies sm ON pm.movie_id = sm.movie_id
ORDER BY 
    sm.production_year DESC, sm.title;
