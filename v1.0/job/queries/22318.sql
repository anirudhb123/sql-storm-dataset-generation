WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS production_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(c.role_id) AS total_roles,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mg.genres,
    ci.total_roles,
    ci.null_notes_count,
    CASE 
        WHEN ci.total_roles > 5 THEN 'Heavy cast'
        WHEN ci.total_roles BETWEEN 1 AND 5 THEN 'Moderate cast'
        ELSE 'No cast' 
    END AS cast_density,
    CASE
        WHEN ml.link_type_id IS NOT NULL THEN 'Linked Movie Exists'
        ELSE 'No Linked Movie'
    END AS link_status
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    CastInfoWithRoles ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    movie_link ml ON rm.movie_id = ml.movie_id
WHERE 
    (rm.production_year >= 2000 OR rm.production_rank <= 10)
    AND (ci.null_notes_count > 0 OR ci.null_notes_count IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
