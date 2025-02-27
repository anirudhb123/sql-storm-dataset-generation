WITH RecursiveCTE AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        SUM(CASE WHEN ca.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        complete_cast c
    JOIN 
        cast_info ca ON c.subject_id = ca.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        COALESCE(d.total_cast, 0) AS total_cast,
        COALESCE(d.role_count, 0) AS role_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        RecursiveCTE d ON t.id = d.movie_id
    WHERE 
        t.production_year > 2000
),
FilteredMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_name,
        md.actor_index,
        md.total_cast,
        md.role_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.role_count DESC, md.total_cast DESC) AS rn
    FROM 
        MovieDetails md
    WHERE 
        md.total_cast > 5
)
SELECT 
    fm.title AS movie_title,
    fm.production_year,
    fm.actor_name,
    fm.actor_index,
    fm.total_cast,
    fm.role_count
FROM 
    FilteredMovies fm
WHERE 
    fm.rn <= 3
ORDER BY 
    fm.production_year DESC, 
    fm.role_count DESC;
