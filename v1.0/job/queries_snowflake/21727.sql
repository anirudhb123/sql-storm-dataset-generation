
WITH RankedMovies AS (
    SELECT 
        a.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY a.id DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY a.movie_id) AS total_cast
    FROM 
        aka_title t
    INNER JOIN 
        cast_info a ON a.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
NullTitleCheck AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        CASE 
            WHEN r.title IS NULL THEN 'Unknown Title'
            ELSE r.title 
        END AS adjusted_title
    FROM 
        RankedMovies r
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CaptivatingMovies AS (
    SELECT 
        nt.movie_id,
        nt.adjusted_title,
        nt.production_year,
        mk.keywords,
        CASE 
            WHEN r.total_cast > 5 THEN 'Epic'
            ELSE 'Modest'
        END AS cast_size_category
    FROM 
        NullTitleCheck nt
    LEFT JOIN 
        MovieKeywords mk ON nt.movie_id = mk.movie_id
    INNER JOIN 
        RankedMovies r ON nt.movie_id = r.movie_id
    WHERE 
        r.rnk = 1
)
SELECT 
    cm.movie_id,
    cm.adjusted_title,
    cm.production_year,
    COALESCE(cm.keywords, 'No Keywords') AS keywords,
    cm.cast_size_category,
    CASE 
        WHEN cm.production_year > 2000 THEN 'Modern Era'
        WHEN cm.production_year BETWEEN 1990 AND 2000 THEN 'Nineties'
        ELSE 'Classic'
    END AS era_category
FROM 
    CaptivatingMovies cm
WHERE 
    cm.movie_id IS NOT NULL
ORDER BY 
    cm.cast_size_category DESC, 
    cm.production_year DESC
LIMIT 50;
