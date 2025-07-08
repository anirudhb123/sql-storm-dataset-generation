
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(c.movie_id) AS total_movies,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.id, a.name
),
HighRatedActors AS (
    SELECT 
        ad.actor_id,
        ad.name,
        ad.total_movies,
        ad.movie_titles,
        COALESCE(AVG(CAST(mi.info AS INTEGER)), 0) AS avg_rating
    FROM 
        ActorDetails ad
    LEFT JOIN 
        complete_cast cc ON ad.actor_id = cc.subject_id
    LEFT JOIN 
        movie_info mi ON cc.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        ad.total_movies > 5
    GROUP BY 
        ad.actor_id, ad.name, ad.total_movies, ad.movie_titles
    HAVING 
        COALESCE(AVG(CAST(mi.info AS INTEGER)), 0) > 7
)
SELECT 
    ra.movie_id,
    ra.title,
    ra.production_year,
    ra.kind_id,
    ha.name AS top_actor,
    ha.avg_rating
FROM 
    RankedMovies ra
JOIN 
    complete_cast cc ON ra.movie_id = cc.movie_id
JOIN 
    HighRatedActors ha ON cc.subject_id = ha.actor_id
WHERE 
    ra.year_rank <= 3
ORDER BY 
    ra.production_year DESC, ha.avg_rating DESC
LIMIT 10;
