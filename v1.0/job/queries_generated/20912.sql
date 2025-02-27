WITH RecursiveYears AS (
    SELECT DISTINCT production_year
    FROM aka_title
    WHERE production_year IS NOT NULL
),
TitleStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(DISTINCT m.id) AS num_movie_companies,
        AVG(COALESCE(CASE WHEN c.note IS NOT NULL THEN LENGTH(c.note) END, 0)) AS avg_note_length,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.movie_id = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id
),
NullHandling AS (
    SELECT 
        title_id,
        title,
        num_movie_companies,
        avg_note_length,
        keyword_count,
        CASE 
            WHEN num_movie_companies IS NULL THEN 'No Companies'
            WHEN avg_note_length IS NULL THEN 'No Notes'
            ELSE 'Data Present'
        END AS data_status
    FROM 
        TitleStats
),
YearRankFilter AS (
    SELECT 
        title_id,
        title,
        data_status,
        num_movie_companies,
        avg_note_length,
        keyword_count
    FROM 
        NullHandling
    WHERE 
        title_id IN (SELECT title_id FROM TitleStats WHERE year_rank <= 5)
)
SELECT 
    y.production_year,
    yf.title,
    yf.num_movie_companies,
    yf.avg_note_length,
    yf.keyword_count,
    yf.data_status
FROM 
    RecursiveYears y
LEFT JOIN 
    YearRankFilter yf ON yf.title_id IN (SELECT id FROM aka_title WHERE production_year = y.production_year)
ORDER BY 
    y.production_year, yf.num_movie_companies DESC, yf.keyword_count DESC
LIMIT 50;
