WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mk.keyword) AS keyword_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names,
        CASE 
            WHEN cd.total_cast > 10 THEN 'Blockbuster'
            WHEN cd.total_cast IS NULL THEN 'Unknown'
            ELSE 'Indie'
        END AS movie_type
    FROM 
        RecursiveMovieCTE rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
)

SELECT 
    mwc.title,
    mwc.production_year,
    mwc.total_cast,
    mwc.cast_names,
    mwc.movie_type,
    COALESCE(NULLIF(mk.keyword, 'No Keyword'), 'No Keywords Available') AS keyword_info,
    CASE 
        WHEN mwc.movie_type = 'Blockbuster' THEN 'Welcome to Hollywood!'
        ELSE 'Keep on filming!'
    END AS movie_message
FROM 
    MoviesWithCast mwc
LEFT JOIN 
    (
        SELECT movie_id, STRING_AGG(keyword, ', ') AS keywords
        FROM movie_keyword
        GROUP BY movie_id
    ) AS mk ON mwc.movie_id = mk.movie_id
WHERE 
    mwc.production_year >= 2000
ORDER BY 
    mwc.production_year DESC, 
    mwc.total_cast DESC
LIMIT 100;

