WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 
        AND rm.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        fm.movie_id, 
        fm.title, 
        fm.production_year, 
        ci.person_id, 
        an.name AS actor_name,
        ct.kind AS role_type,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        complete_cast cc ON fm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        role_type ct ON ci.role_id = ct.id
    LEFT JOIN 
        movie_info mi ON fm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.cast_count, 
    STRING_AGG(CONCAT(md.actor_name, ' (', COALESCE(md.role_type, 'N/A'), ')'), ', ') AS actors,
    COUNT(DISTINCT md.movie_info) AS info_count
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, 
    COUNT(md.actor_name) DESC;
