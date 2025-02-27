WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_info b ON a.movie_id = b.movie_id
    WHERE 
        b.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
        AND a.production_year BETWEEN 2000 AND 2023
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
HighlyRatedMovies AS (
    SELECT 
        m.movie_id,
        AVG(i.info::float) AS average_rating
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info = 'Rating'
    GROUP BY 
        m.movie_id
    HAVING 
        AVG(i.info::float) >= 8.0
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        hr.average_rating
    FROM 
        RankedMovies rm
    JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    JOIN 
        HighlyRatedMovies hr ON rm.movie_id = hr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.average_rating,
    c.name AS lead_actor
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    aka_name c ON ci.person_id = c.person_id
WHERE 
    ci.nr_order = 1
ORDER BY 
    md.average_rating DESC, 
    md.title ASC;
