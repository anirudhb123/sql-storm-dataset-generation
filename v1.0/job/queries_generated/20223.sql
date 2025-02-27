WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS year_rank
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id 
    GROUP BY 
        ci.movie_id
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS rating,
        MAX(CASE WHEN it.info = 'synopsis' THEN mi.info END) AS synopsis
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
RelevantLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        COUNT(DISTINCT ml.link_type_id) AS link_type_count
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        lt.link LIKE '%sequel%'
    GROUP BY 
        ml.movie_id, ml.linked_movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names,
        mid.rating,
        mid.synopsis,
        COALESCE(rl.link_type_count, 0) AS sequel_links
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieInfoDetails mid ON rm.movie_id = mid.movie_id
    LEFT JOIN 
        RelevantLinks rl ON rm.movie_id = rl.movie_id
)
SELECT 
    *,
    CASE 
        WHEN total_cast IS NULL THEN 'No Cast'
        WHEN rating IS NULL THEN CONCAT('Rating Not Available for ', title)
        ELSE 'Data Complete'
    END AS data_status
FROM 
    FinalResults
WHERE 
    production_year > 2000 
    AND (sequel_links > 1 OR rating IS NOT NULL)
ORDER BY 
    production_year DESC, sequel_links DESC;
