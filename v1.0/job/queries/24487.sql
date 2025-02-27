WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ci.nr_order) AS role_rank,
        COUNT(*) OVER (PARTITION BY at.id) AS total_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        role,
        role_rank,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        total_cast > 3
)

SELECT 
    F.title,
    F.production_year,
    COALESCE(F.role, 'Unknown Role') AS role,
    CASE 
        WHEN F.role_rank IS NULL THEN 'No Roles Assigned'
        WHEN F.role_rank = 1 THEN 'Lead Role'
        ELSE CONCAT('Supporting Role ', F.role_rank - 1)
    END AS role_description,
    CASE 
        WHEN F.production_year IS NULL THEN 'Year Unknown' 
        ELSE CAST(F.production_year AS text) 
    END AS production_year_text,
    COUNT(DISTINCT ci.person_id) AS distinct_actors,
    STRING_AGG(DISTINCT C.name, ', ') AS co_stars
FROM 
    FilteredMovies F
LEFT JOIN 
    cast_info ci ON F.title_id = ci.movie_id
LEFT JOIN 
    aka_name C ON ci.person_id = C.person_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = F.title_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
        AND mi.info IS NOT NULL
    )
GROUP BY 
    F.title_id, F.title, F.production_year, F.role, F.role_rank
ORDER BY 
    F.production_year DESC, 
    F.title;
