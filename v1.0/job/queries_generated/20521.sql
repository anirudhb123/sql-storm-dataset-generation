WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        COALESCE(mi.info, 'No info available') AS movie_info,
        ARRAY_AGG(DISTINCT ct.kind) AS company_kinds
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = rm.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rm.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = rm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
    GROUP BY 
        rm.title, rm.production_year, rm.actor_count
),
NullHandling AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        md.movie_info,
        md.company_kinds,
        (CASE 
            WHEN md.actor_count IS NULL THEN 0 
            ELSE md.actor_count 
        END) AS safe_actor_count,
        (CASE 
            WHEN md.movie_info IS NULL THEN 'Information missing'
            ELSE md.movie_info 
        END) AS formatted_movie_info
    FROM 
        MovieDetails md
)
SELECT 
    nh.title,
    nh.production_year,
    nh.safe_actor_count,
    nh.formatted_movie_info,
    CASE 
        WHEN nh.company_kinds IS NULL THEN ARRAY['Unknown company'] 
        ELSE nh.company_kinds 
    END AS displayed_company_kinds,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT person_id FROM cast_info ci WHERE ci.movie_id = (SELECT movie_id FROM aka_title WHERE title = nh.title LIMIT 1))) AS total_unique_actors
FROM 
    NullHandling nh
WHERE 
    nh.actor_count > 0 AND
    nh.production_year >= 2000
ORDER BY 
    nh.production_year DESC, nh.safe_actor_count DESC
LIMIT 50;


