WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        nt.kind AS movie_kind,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    LEFT JOIN 
        kind_type nt ON t.kind_id = nt.id
    GROUP BY 
        t.id, t.title, t.production_year, nt.kind
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_kind,
        rm.cast_count,
        rm.actor_names,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.movie_kind, rm.cast_count, rm.actor_names
),

FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.movie_kind,
        md.cast_count,
        md.actor_names,
        md.keyword_count,
        md.movie_info,
        LENGTH(md.title) AS title_length,
        UPPER(md.title) AS title_in_uppercase,
        LOWER(md.actor_names) AS actor_names_in_lowercase
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000
    ORDER BY 
        md.cast_count DESC, md.production_year DESC
    LIMIT 100
)

SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.movie_kind,
    fb.cast_count,
    fb.actor_names,
    fb.keyword_count,
    fb.movie_info,
    fb.title_length,
    fb.title_in_uppercase,
    fb.actor_names_in_lowercase
FROM 
    FinalBenchmark fb;
