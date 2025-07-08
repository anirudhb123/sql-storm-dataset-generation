WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(cr.role, 'Unknown Role') AS role,
    cr.num_cast,
    cr.null_notes_count,
    CASE 
        WHEN m.year_rank <= 5 THEN 'Top 5 Latest Movies'
        ELSE 'Other Movies'
    END AS ranking_category
FROM 
    RankedMovies m
LEFT JOIN 
    CastRoles cr ON m.movie_id = cr.movie_id
WHERE 
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE 
            mi.movie_id = m.movie_id AND 
            mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis') 
            AND mi.info IS NOT NULL
    )
ORDER BY 
    m.production_year DESC, 
    cr.num_cast DESC NULLS LAST;
