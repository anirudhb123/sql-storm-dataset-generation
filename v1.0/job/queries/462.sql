WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year,
        COALESCE(cm.name, 'Unknown Company') AS company_name,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.title, t.production_year, cm.name
), RankedMovies AS (
    SELECT 
        title, 
        production_year, 
        company_name, 
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        MovieDetails
), YearlyCastingStats AS (
    SELECT 
        production_year, 
        AVG(cast_count) AS avg_cast_count,
        MAX(cast_count) AS max_cast_count,
        MIN(cast_count) AS min_cast_count
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)
SELECT 
    r.title, 
    r.production_year, 
    r.company_name, 
    r.cast_count,
    s.avg_cast_count,
    s.max_cast_count,
    s.min_cast_count
FROM 
    RankedMovies r
JOIN 
    YearlyCastingStats s ON r.production_year = s.production_year
WHERE 
    r.rank_within_year <= 5
ORDER BY 
    r.production_year DESC, 
    r.cast_count DESC;
