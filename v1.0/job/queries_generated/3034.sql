WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_title,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    WHERE 
        at.production_year >= 2000
),
HighCastMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rank_title
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
),
RecentAwardMovies AS (
    SELECT 
        m.title,
        m.production_year
    FROM 
        movie_info mi
    JOIN 
        title m ON mi.movie_id = m.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Won Award')
        AND m.production_year > (SELECT MAX(production_year) - 5 FROM title)
)
SELECT 
    h.title AS movie_title,
    h.production_year,
    COALESCE(h.rank_title, 'Not Ranked') AS title_rank,
    CASE
        WHEN h.production_year IN (SELECT production_year FROM RecentAwardMovies) THEN 'Awarded'
        ELSE 'No Award'
    END AS award_status
FROM 
    HighCastMovies h
FULL OUTER JOIN 
    RecentAwardMovies r ON h.title = r.title AND h.production_year = r.production_year
WHERE 
    h.production_year IS NOT NULL 
    OR r.production_year IS NOT NULL
ORDER BY 
    h.production_year DESC, h.title;
