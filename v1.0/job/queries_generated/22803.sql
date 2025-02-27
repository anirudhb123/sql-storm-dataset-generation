WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithKeywordCount AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
MoviesWithCast AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(COUNT(c.person_id), 0) AS cast_count
    FROM 
        MoviesWithKeywordCount m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id, m.title
),
HighKeywordMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.keyword_count,
        mc.cast_count
    FROM 
        MoviesWithKeywordCount mwk
    INNER JOIN 
        MoviesWithCast mc ON mwk.movie_id = mc.movie_id
    WHERE 
        mwk.keyword_count > 3 AND mc.cast_count > 0
),
FinalResults AS (
    SELECT 
        hkm.movie_id,
        hkm.title,
        hkm.production_year,
        hkm.keyword_count,
        hkm.cast_count,
        COALESCE(mi.info, 'No Info Available') AS movie_info,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        HighKeywordMovies hkm
    LEFT JOIN 
        movie_info mi ON hkm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration' LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON hkm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.cast_count,
    STRING_AGG(DISTINCT fr.keyword, ', ') AS keywords,
    (CASE 
        WHEN fr.cast_count IS NULL THEN 'No Cast'
        ELSE 'Cast Available'
     END) AS cast_availability,
    (CASE
        WHEN fr.cast_count = 0 THEN NULL
        ELSE fr.cast_count /
            (SELECT COUNT(*) FROM MoviesWithCast)
     END) AS normalized_cast_count
FROM 
    FinalResults fr
GROUP BY 
    fr.movie_id, fr.title, fr.production_year, fr.keyword_count, fr.cast_count
HAVING 
    fr.keyword_count > 4
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC;
