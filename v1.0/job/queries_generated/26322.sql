WITH RankedTitles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        MAX(t.production_year) OVER(PARTITION BY t.production_year) AS max_year
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.movie_id,
        rt.title,
        rt.production_year,
        rt.cast_count,
        rt.actors,
        rt.max_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.cast_count > 5 
        AND rt.production_year >= 2000
)
SELECT 
    ft.title,
    ft.production_year,
    ft.cast_count,
    ft.actors,
    COUNT(*) OVER() AS total_filtered_movies
FROM 
    FilteredTitles ft
ORDER BY 
    ft.production_year DESC, ft.cast_count DESC;
