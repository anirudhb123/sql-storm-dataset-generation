WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rnk
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT m.movie_id) AS movies_count
    FROM 
        cast_info c
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN 
        ak_name a ON c.person_id = a.person_id
    JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    WHERE 
        rm.rnk <= 10
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT m.movie_id) > 2
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        pa.movies_count
    FROM 
        person_info pa
    JOIN 
        PopularActors pa ON pa.person_id = p.id
)
SELECT 
    ad.name,
    COUNT(m.movie_id) AS total_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    COALESCE(MAX(p.info), 'No Info Available') AS additional_info
FROM 
    ActorDetails ad
LEFT JOIN 
    cast_info ci ON ad.person_id = ci.person_id
LEFT JOIN 
    aka_title m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    ad.name, ad.movies_count
ORDER BY 
    total_movies DESC
LIMIT 10;
