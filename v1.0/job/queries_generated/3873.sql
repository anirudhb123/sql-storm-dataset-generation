WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(COUNT(ci.person_id), 0) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS average_note
    FROM 
        rankedmovies rm
    LEFT JOIN 
        aka_title at ON at.title = rm.title
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = at.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        m.id, m.title
    HAVING 
        COUNT(ci.person_id) > 0
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_summary
    FROM 
        movie_info mi
    JOIN 
        movie_details md ON md.movie_id = mi.movie_id
    GROUP BY 
        mi.movie_id
), FilteredMovies AS (
    SELECT 
        md.*, 
        mi.info_summary
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    WHERE 
        md.cast_count > 5
    AND 
        md.average_note > 0
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.info_summary,
    COALESCE(mn.name, 'Unknown') AS main_actor
FROM 
    filteredmovies fm
LEFT JOIN 
    cast_info ci ON ci.movie_id = fm.movie_id
LEFT JOIN 
    aka_name mn ON mn.person_id = ci.person_id
WHERE 
    fm.production_year BETWEEN 2000 AND 2023
AND 
    mn.name IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
