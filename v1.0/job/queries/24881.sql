
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MissingTitles AS (
    SELECT 
        DISTINCT year.year AS missing_year 
    FROM 
        (SELECT DISTINCT production_year AS year FROM aka_title) AS year
    LEFT JOIN 
        RankedMovies rm ON year.year = rm.production_year
    WHERE 
        rm.title_id IS NULL
),
CastingInfo AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS num_actors,
        MAX(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS has_female_cast,
        MAX(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS has_male_cast,
        AVG(COALESCE(CASE WHEN p.gender = 'F' THEN 1 ELSE NULL END, 0)) AS avg_female_ratio
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.id
    GROUP BY 
        c.movie_id
),
FinalOutput AS (
    SELECT 
        rm.title_id,
        rm.title,
        COALESCE(c.num_actors, 0) AS num_actors,
        COALESCE(c.has_female_cast, 0) AS has_female_cast,
        COALESCE(c.has_male_cast, 0) AS has_male_cast,
        COALESCE(c.avg_female_ratio, 0) AS avg_female_ratio,
        m.missing_year,
        rm.production_year
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastingInfo c ON rm.title_id = c.movie_id
    LEFT JOIN 
        MissingTitles m ON rm.production_year = m.missing_year
)
SELECT 
    f.title_id,
    f.title,
    f.num_actors,
    f.has_female_cast,
    f.has_male_cast,
    CASE 
        WHEN f.avg_female_ratio > 0.5 THEN 'Female-Dominated'
        WHEN f.avg_female_ratio < 0.5 THEN 'Male-Dominated'
        ELSE 'Balanced'
    END AS gender_ratio,
    CASE 
        WHEN f.missing_year IS NOT NULL THEN 'Missing Year'
        ELSE 'Present Year'
    END AS year_status
FROM 
    FinalOutput f
WHERE 
    f.num_actors > 0
ORDER BY 
    f.production_year, f.title;
