WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mi.info) AS info_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        movie_info mi ON at.id = mi.movie_id
    GROUP BY 
        at.title, at.production_year
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MoviesWithActors AS (
    SELECT 
        rm.title,
        rm.production_year,
        pa.name AS actor_name,
        rm.info_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = (SELECT id FROM aka_title where title = rm.title LIMIT 1)
    LEFT JOIN 
        aka_name pa ON ci.person_id = pa.person_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_name,
    COALESCE(m.info_count, 0) AS movie_info_count,
    CASE 
        WHEN m.actor_name IS NULL THEN 'No Actor'
        ELSE m.actor_name 
    END AS display_actor_name
FROM 
    MoviesWithActors m
WHERE 
    m.year_rank <= 5
ORDER BY 
    m.production_year DESC, m.title;
