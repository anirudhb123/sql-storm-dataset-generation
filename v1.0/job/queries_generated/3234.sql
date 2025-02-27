WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, 
        at.production_year
), 
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
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
MovieDetails AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(NULLIF(mn.info, ''), 'N/A') AS movie_info,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mn ON at.movie_id = mn.movie_id AND mn.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        at.id, at.title, at.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.movie_info,
    md.actor_names,
    (SELECT COUNT(*) FROM RankedMovies rm WHERE rm.production_year = md.production_year AND rm.rank <= 3) AS top_movie_count,
    pa.movie_count AS popular_actor_count
FROM 
    MovieDetails md
LEFT JOIN 
    PopularActors pa ON md.actor_names::text[] @> ARRAY[pa.actor_name]
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title;
