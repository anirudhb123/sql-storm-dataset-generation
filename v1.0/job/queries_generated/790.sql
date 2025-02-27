WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
), FilteredMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
), MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        AVG(CASE WHEN m.info_type_id = 1 THEN (m.info)::float END) AS avg_budget,
        STRING_AGG(DISTINCT p.info, ', ') AS producers
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_info m ON f.production_year = m.movie_id
    LEFT JOIN 
        movie_companies mc ON f.production_year = mc.movie_id
    LEFT JOIN 
        company_name p ON mc.company_id = p.id
    GROUP BY 
        f.title, f.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.avg_budget, 0) AS avg_budget,
    COALESCE(md.producers, 'None') AS producers
FROM 
    MovieDetails md
WHERE 
    md.avg_budget > (SELECT AVG(avg_budget) FROM MovieDetails)
ORDER BY 
    md.production_year DESC, md.title;
