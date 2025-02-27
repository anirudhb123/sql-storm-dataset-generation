WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_avg
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        t.production_year >= 2000
        AND (it.info IS NULL OR it.info != 'Banned')
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorNames AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL
),
RankedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        md.has_note_avg,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS year_rank
    FROM 
        MovieDetails md
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.has_note_avg,
    STRING_AGG(an.actor_name, ', ') AS actor_names
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorNames an ON rm.title = an.movie_id
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.title, rm.production_year, rm.actor_count, rm.has_note_avg
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
