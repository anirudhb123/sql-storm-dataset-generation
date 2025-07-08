
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
DramaMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        CASE 
            WHEN md.actor_count > 5 THEN 'High Actor Count'
            ELSE 'Low Actor Count'
        END AS actor_group,
        md.actor_names
    FROM 
        MovieDetails md
    WHERE 
        EXISTS (
            SELECT 1 
            FROM movie_keyword mk 
            WHERE mk.movie_id = md.movie_id 
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword = 'Drama')
        )
)
SELECT 
    dm.movie_id,
    dm.movie_title,
    dm.production_year,
    dm.actor_group,
    COALESCE(NULLIF(dm.actor_names, ''), 'No Actors Listed') AS actor_names,
    ROW_NUMBER() OVER (PARTITION BY dm.actor_group ORDER BY dm.production_year DESC) AS rank_within_group
FROM 
    DramaMovies dm
ORDER BY 
    dm.actor_group, 
    dm.production_year DESC;
