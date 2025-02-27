WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CastDetails AS (
    SELECT 
        c.id AS cast_id,
        p.person_id,
        p.name AS person_name,
        r.role AS role_name,
        m.title,
        m.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        TopMovies m ON c.movie_id = m.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
),
FilmStats AS (
    SELECT 
        movie_id,
        COUNT(cast_id) AS total_cast,
        AVG(DISTINCT CASE WHEN role_name IS NOT NULL THEN 1 ELSE NULL END) AS avg_roles
    FROM 
        CastDetails
    GROUP BY 
        movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    f.total_cast,
    f.avg_roles,
    COALESCE(NULLIF(m.production_year - 2023, 0), 'Current Year') AS year_difference_indicator
FROM 
    TopMovies m
LEFT JOIN 
    FilmStats f ON m.movie_id = f.movie_id
WHERE 
    (m.production_year BETWEEN 2000 AND 2023 OR f.total_cast IS NULL)
ORDER BY 
    m.production_year DESC, f.total_cast DESC;
