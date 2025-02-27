WITH RecursiveMovieChain AS (
    SELECT 
        mv.id AS movie_id,
        mv.title AS movie_title,
        1 AS depth,
        mv.production_year
    FROM 
        aka_title mv
    WHERE 
        mv.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        at.title AS movie_title,
        depth + 1,
        at.production_year
    FROM 
        movie_link m
    JOIN 
        aka_title at ON m.linked_movie_id = at.id
    JOIN 
        RecursiveMovieChain r ON m.movie_id = r.movie_id
    WHERE 
        r.depth < 5
),
AggregatedCastInfo AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(a.name, ' as ', rt.role), ', ') AS cast,
        COUNT(c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        rmc.movie_id,
        rmc.movie_title,
        rmc.production_year,
        aci.cast,
        aci.total_cast
    FROM 
        RecursiveMovieChain rmc
    LEFT JOIN 
        AggregatedCastInfo aci ON rmc.movie_id = aci.movie_id
    WHERE 
        rmc.production_year = (
            SELECT 
                MAX(production_year)
            FROM 
                RecursiveMovieChain
            WHERE 
                movie_id = rmc.movie_id
        )
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    COALESCE(fm.cast, 'Unknown Cast') AS cast_info,
    COALESCE(fm.total_cast, 0) AS total_cast_count,
    CASE 
        WHEN fm.total_cast IS NULL THEN 'Cast Information Unavailable'
        WHEN fm.total_cast > 5 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_size_description,
    ROW_NUMBER() OVER (ORDER BY fm.production_year DESC) AS rank
FROM 
    FilteredMovies fm
WHERE 
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = fm.movie_id
          AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
          AND LENGTH(mi.info) > 0
    )
ORDER BY 
    fm.production_year DESC,
    rank;

