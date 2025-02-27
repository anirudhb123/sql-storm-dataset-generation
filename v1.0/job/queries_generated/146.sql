WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS num_cast_members
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
),
FilteredTitles AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        rm.num_cast_members
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCount cc ON rm.id = cc.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    ft.title,
    ft.production_year,
    ft.company_count,
    ft.num_cast_members,
    CASE 
        WHEN ft.num_cast_members > 10 THEN 'Large Cast'
        WHEN ft.num_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    FilteredTitles ft
WHERE 
    (ft.company_count > 0 OR ft.num_cast_members > 5)
ORDER BY 
    ft.production_year DESC, 
    ft.company_count DESC;
