
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS actor_names,
        MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No additional notes' END) AS additional_notes
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_actors,
        md.actor_names,
        CASE 
            WHEN md.total_actors > 5 THEN 'Blockbuster'
            WHEN md.total_actors BETWEEN 3 AND 5 THEN 'Moderate'
            WHEN md.total_actors < 3 THEN 'Indie'
            ELSE 'Undefined'
        END AS movie_type
    FROM 
        MovieDetails md
    WHERE 
        md.production_year BETWEEN 1990 AND 2023 
        AND md.actor_names IS NOT NULL
),
FinalOutput AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.total_actors,
        f.actor_names,
        f.movie_type,
        EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = f.movie_id AND mi.info_type_id = 1) AS has_additional_info
    FROM 
        FilteredMovies f
    WHERE 
        f.movie_type IN ('Blockbuster', 'Moderate')
)

SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.total_actors,
    fo.actor_names,
    fo.movie_type,
    fo.has_additional_info,
    ml.linked_movie_id
FROM 
    FinalOutput fo
LEFT JOIN 
    movie_link ml ON fo.movie_id = ml.movie_id
WHERE 
    ml.linked_movie_id IS NULL 
    OR ml.linked_movie_id IN (SELECT DISTINCT movie_id FROM aka_title WHERE title ILIKE '%Action%')
ORDER BY 
    fo.production_year DESC, 
    fo.total_actors DESC;
