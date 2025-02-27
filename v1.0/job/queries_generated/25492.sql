WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        kt.kind AS movie_kind,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        RankedMovies rm
    JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        kind_type kt ON rm.kind_id = kt.id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, kt.kind
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_kind,
        md.actor_count,
        md.actor_names,
        STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year, md.movie_kind, md.actor_count, md.actor_names
)
SELECT 
    mi.movie_title,
    mi.production_year,
    mi.movie_kind,
    mi.actor_count,
    mi.actor_names,
    mi.additional_info
FROM 
    MovieInfo mi
ORDER BY 
    mi.production_year DESC,  mi.movie_title;
