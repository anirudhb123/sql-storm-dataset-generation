WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN mi.info_type_id = it.id AND it.info = 'Box Office' THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS box_office
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mt.id
    LEFT JOIN 
        info_type it ON it.id = mi.info_type_id
    WHERE 
        mt.production_year > 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

RankedMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actor_names,
        md.company_count,
        md.box_office,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.box_office DESC) AS box_office_rank
    FROM 
        MovieDetails md
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actor_names,
    rm.company_count,
    COALESCE(rm.box_office, 0) AS box_office,
    rm.box_office_rank
FROM 
    RankedMovies rm
WHERE 
    rm.box_office_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.box_office DESC

