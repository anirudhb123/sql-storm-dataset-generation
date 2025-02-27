WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) OVER (PARTITION BY t.id) AS has_notes,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        COALESCE(rm.has_notes, 0) AS has_notes
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    COALESCE(NULLIF(f.has_notes, 0), 'No Notes') AS notes_status,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_actor_names
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info c ON f.title_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
GROUP BY 
    f.title_id, f.title, f.production_year, f.actor_count, f.has_notes
ORDER BY 
    f.production_year DESC, f.actor_count DESC;
