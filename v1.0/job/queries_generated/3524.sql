WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank_order,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT d.id) AS company_count,
        SUM(e.info IS NOT NULL) AS info_entries
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    LEFT JOIN 
        movie_companies c ON a.id = c.movie_id
    LEFT JOIN 
        company_name d ON c.company_id = d.id
    LEFT JOIN 
        movie_info e ON a.id = e.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
),
SelectedMovies AS (
    SELECT 
        movie_title,
        production_year,
        rank_order,
        cast_names,
        company_count,
        info_entries
    FROM 
        RankedMovies
    WHERE 
        company_count > 0
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.cast_names,
    sm.company_count,
    sm.info_entries,
    CASE 
        WHEN sm.rank_order = 1 THEN 'Top Movie of Year'
        ELSE 'Other Movie'
    END AS status,
    COALESCE(NULLIF(sm.production_year, 2023), 'Future Release') AS production_status
FROM 
    SelectedMovies sm
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = (SELECT a.id FROM aka_title a WHERE a.title = sm.movie_title LIMIT 1)
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%' OR keyword LIKE '%Drama%')
    )
ORDER BY 
    sm.production_year DESC, 
    sm.rank_order;
