WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(c.movie_id) AS cast_count
    FROM 
        aka_title t
        LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
SubQuery AS (
    SELECT 
        m.title_id,
        m.title,
        m.production_year,
        m.cast_count,
        (SELECT COUNT(*) 
         FROM movie_info mi 
         WHERE mi.movie_id = m.title_id AND mi.info_type_id IN 
               (SELECT id FROM info_type WHERE info = 'Budget')) AS budget_count
    FROM 
        RankedMovies m
    WHERE 
        m.cast_count > 2
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.cast_count, 0) AS cast_count,
    COALESCE(b.budget_count, 0) AS budget_count,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(m.production_year AS TEXT)
    END AS year_label
FROM 
    SubQuery m
LEFT JOIN (
    SELECT 
        movie_id, COUNT(*) AS budget_count 
    FROM 
        movie_info 
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    GROUP BY 
        movie_id
) b ON m.title_id = b.movie_id
WHERE 
    m.budget_count > 0 OR m.cast_count >= 5
ORDER BY 
    m.production_year DESC, 
    m.cast_count DESC;
