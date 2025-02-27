WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC, title.title) AS rank_by_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS summary
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
), 
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.actor_names,
        md.summary,
        RANK() OVER (ORDER BY md.total_cast DESC) AS cast_rank
    FROM 
        MovieDetails md
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    COALESCE(tm.actor_names[1], 'Unknown Actor') AS lead_actor,
    tm.summary
FROM 
    TopMovies tm
WHERE 
    tm.cast_rank <= 10
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
