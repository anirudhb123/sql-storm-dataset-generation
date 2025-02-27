WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count,
        COUNT(ci.person_id) AS total_actors
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        rm.actor_count <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ad.actor_name,
    ad.title,
    ad.production_year,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ad.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')) AS plot_count
FROM 
    ActorDetails ad
LEFT JOIN 
    MovieKeywords mk ON ad.movie_id = mk.movie_id
WHERE 
    ad.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ad.production_year DESC, 
    ad.actor_name;
