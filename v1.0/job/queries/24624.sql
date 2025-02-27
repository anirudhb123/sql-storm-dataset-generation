WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        at.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year
    FROM
        aka_title at
    WHERE
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND at.production_year IS NOT NULL
),

TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(CASE WHEN c.nr_order = 1 THEN ak.name END) AS leading_actor
    FROM
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        rm.rank_per_year <= 5   
    GROUP BY 
        rm.title, rm.production_year, rm.movie_id
),

MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

FinalSummary AS (
    SELECT 
        tm.production_year,
        tm.title,
        tm.total_cast,
        COALESCE(tm.leading_actor, 'Unknown Actor') AS leading_actor,
        COALESCE(mkc.keyword_count, 0) AS total_keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywordCount mkc ON tm.movie_id = mkc.movie_id
)
SELECT 
    fs.production_year,
    fs.title,
    fs.total_cast,
    fs.leading_actor,
    fs.total_keywords,
    CASE 
        WHEN fs.total_cast = 0 THEN 'No Cast'
        WHEN fs.total_keywords = 0 THEN 'No Keywords'
        ELSE 'Complete Data'
    END AS data_status
FROM 
    FinalSummary fs
WHERE 
    fs.total_cast > 0
ORDER BY 
    fs.production_year DESC, fs.total_keywords DESC;