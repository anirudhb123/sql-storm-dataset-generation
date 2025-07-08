WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        hcm.movie_id,
        hcm.title,
        hcm.production_year,
        COALESCE(mi.info, 'No info available') AS info
    FROM 
        HighCastMovies hcm
    LEFT JOIN 
        movie_info mi ON hcm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
),
KeywordCounts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.info,
    kc.keyword_count,
    CASE 
        WHEN kc.keyword_count IS NULL THEN 'No Keywords'
        WHEN kc.keyword_count > 5 THEN 'Rich' 
        ELSE 'Moderate' 
    END AS keyword_richness
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCounts kc ON md.movie_id = kc.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.title;
