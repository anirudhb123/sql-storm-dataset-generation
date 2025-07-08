
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id
),
HighCastMovies AS (
    SELECT 
        r.*,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE WHEN r.cast_count > 5 THEN 'High' ELSE 'Low' END AS cast_quality
    FROM 
        RankedMovies r
    LEFT JOIN 
        MoviesWithKeywords mk ON r.movie_id = mk.movie_id
    WHERE 
        r.rank_by_cast <= 5
),
MoviesInfo AS (
    SELECT 
        hcm.movie_id,
        MAX(m.note) AS max_note
    FROM 
        HighCastMovies hcm
    LEFT JOIN 
        complete_cast cc ON hcm.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info m ON cc.movie_id = m.movie_id
    GROUP BY 
        hcm.movie_id
)
SELECT 
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    hcm.keywords,
    hcm.cast_quality,
    COALESCE(mi.max_note, 'No Note') AS note
FROM 
    HighCastMovies hcm
LEFT JOIN 
    MoviesInfo mi ON hcm.movie_id = mi.movie_id
WHERE 
    hcm.cast_quality = 'High' AND 
    (hcm.keywords LIKE '%Action%' OR hcm.keywords LIKE '%Drama%')
ORDER BY 
    hcm.production_year DESC, 
    hcm.cast_count DESC;
