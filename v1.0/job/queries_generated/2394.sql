WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT mi.info) AS movie_details
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.title = mi.info
    WHERE 
        m.rank <= 10
    GROUP BY 
        m.title, m.production_year
),
KeywordCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mt.movie_id = mk.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.movie_details, 'No Details Available') AS movie_details,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN kc.keyword_count IS NULL THEN 'No Keywords'
        WHEN kc.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Known'
    END AS popularity
FROM 
    MovieInfo m
LEFT JOIN 
    KeywordCounts kc ON m.title = kc.movie_id
ORDER BY 
    m.production_year DESC, m.title;
