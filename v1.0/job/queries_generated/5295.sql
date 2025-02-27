WITH MovieRankings AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT m.id) AS company_count,
        AVG(m.production_year) AS average_company_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id
),
PopularMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        company_count,
        average_company_year,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_by_cast,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS row_number_by_year
    FROM 
        MovieRankings
)

SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.company_count,
    pm.average_company_year
FROM 
    PopularMovies pm
WHERE 
    pm.row_number_by_year <= 5
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC;
