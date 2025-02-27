WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
PopularActors AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
ActorNames AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS actor_names
    FROM 
        aka_name ak
    JOIN 
        PopularActors pa ON ak.person_id = pa.person_id
    GROUP BY 
        ak.person_id
),
ActorMovies AS (
    SELECT 
        pa.person_id,
        rm.title,
        rm.production_year
    FROM 
        PopularActors pa
    JOIN 
        cast_info ci ON pa.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
)
SELECT 
    am.actor_names,
    am.title,
    am.production_year,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    MIN(COALESCE(mk.keyword, 'No Keyword')) AS first_keyword,
    MAX(CASE WHEN m.production_year < 2010 THEN 'Before 2010' ELSE '2010 or Later' END) AS movie_epoch
FROM 
    ActorNames am
LEFT JOIN 
    movie_keyword mk ON am.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON am.movie_id = mi.movie_id
JOIN 
    ActorMovies amv ON am.person_id = amv.person_id
JOIN 
    title mt ON amv.title = mt.title
WHERE 
    mi.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE '%Award%'
    )
GROUP BY 
    am.actor_names, am.title, am.production_year
ORDER BY 
    total_movies DESC, am.actor_names;
