WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
    GROUP BY c.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        mi.info AS movie_info,
        COALESCE(NULLIF(mi.note, ''), 'No note available') AS note_info
    FROM movie_info m
    LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.total_cast,
    cd.cast_names,
    mi.movie_info,
    mi.note_info
FROM RankedMovies rm
LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    (mi.movie_info IS NULL OR mi.movie_info LIKE '%Drama%')
    AND (cd.total_cast > 3 OR cd.total_cast IS NULL)
    AND rm.title_rank BETWEEN 1 AND 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 10;