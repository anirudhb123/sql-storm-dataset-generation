WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id, 
        title.title AS movie_title, 
        title.production_year, 
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.person_id) DESC) AS rn,
        SUM(CASE WHEN cast_info.role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        total_roles 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count,
        COALESCE(NULLIF(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0), 0) AS note_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    GROUP BY 
        tm.movie_id, tm.movie_title, tm.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.info_count,
    md.note_count,
    (SELECT AVG(total_roles) FROM TopMovies) AS avg_roles,
    CASE 
        WHEN md.info_count = 0 THEN 'No info available' 
        ELSE 'Info available' 
    END AS info_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.note_count DESC;
