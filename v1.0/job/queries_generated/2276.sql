WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND at.production_year IS NOT NULL
), MovieGenres AS (
    SELECT 
        m.id AS movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
), CastDetails AS (
    SELECT 
        c.movie_id, 
        COUNT(c.id) AS total_cast, 
        ARRAY_AGG(DISTINCT ak.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
), MoviesWithDetails AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        mg.genres,
        cd.total_cast,
        cd.cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.title = mg.movie_id
    LEFT JOIN 
        CastDetails cd ON rm.title = cd.movie_id
)
SELECT 
    mw.title, 
    mw.production_year, 
    COALESCE(mw.genres, 'Unknown') AS genres,
    mw.total_cast,
    CASE 
        WHEN mw.total_cast IS NULL THEN 'No Cast Available'
        ELSE ARRAY_TO_STRING(mw.cast_names, ', ')
    END AS cast_list
FROM 
    MoviesWithDetails mw
WHERE 
    mw.rank <= 5
ORDER BY 
    mw.production_year DESC, mw.title;
