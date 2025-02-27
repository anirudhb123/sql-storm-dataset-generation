WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
TitleAndCast AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(m.total_cast, 0) AS total_cast
    FROM 
        RankedTitles t
    LEFT JOIN 
        MovieCastInfo m ON t.title_id = m.movie_id
    WHERE 
        t.title_rank <= 10
),
TitleSummary AS (
    SELECT 
        production_year,
        AVG(total_cast) AS avg_cast,
        COUNT(title) AS title_count
    FROM 
        TitleAndCast
    GROUP BY 
        production_year
)
SELECT 
    ts.production_year,
    ts.avg_cast,
    ts.title_count,
    CASE 
        WHEN ts.avg_cast IS NULL THEN 'No Data'
        WHEN ts.avg_cast > 10 THEN 'High Cast'
        ELSE 'Low Cast'
    END AS cast_density
FROM 
    TitleSummary ts
ORDER BY 
    ts.production_year DESC;
