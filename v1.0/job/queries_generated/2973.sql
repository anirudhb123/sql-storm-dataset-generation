WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY m.info DESC) AS rank_info
    FROM 
        title t
    JOIN 
        movie_info m ON t.id = m.movie_id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.total_cast,
    mc.cast_names,
    mwk.keywords,
    CASE 
        WHEN mc.total_cast IS NULL THEN 'No cast'
        ELSE 'Cast available'
    END AS cast_status,
    COALESCE(mw1.info, 'N/A') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
LEFT JOIN 
    movie_info_idx mw1 ON rm.movie_id = mw1.movie_id AND mw1.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    rm.rank_info <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
