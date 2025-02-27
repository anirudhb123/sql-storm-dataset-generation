WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        m.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank_by_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS total_cast,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS male_cast_count,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS female_cast_count
    FROM 
        aka_title a 
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = a.id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    LEFT JOIN 
        name p ON p.id = ci.person_id
    WHERE 
        a.production_year IS NOT NULL 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN male_cast_count > female_cast_count THEN 'More Males'
            WHEN female_cast_count > male_cast_count THEN 'More Females'
            ELSE 'Equal Gender Representation'
        END AS gender_representation
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 5
),
FinalOutput AS (
    SELECT 
        f.title,
        f.production_year,
        f.company_name,
        f.gender_representation,
        COALESCE(NULLIF(f.total_cast, 0), 'No Cast Available') AS cast_info,
        CASE 
            WHEN f.gender_representation = 'More Males' THEN 'Great male presence'
            WHEN f.gender_representation = 'More Females' THEN 'Strong female voice'
            ELSE 'Gender balanced'
        END AS commentary
    FROM 
        FilteredMovies f
)
SELECT 
    title,
    production_year,
    company_name,
    gender_representation,
    cast_info,
    commentary
FROM 
    FinalOutput
WHERE 
    (cast_info <> 'No Cast Available' OR NOT EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = FinalOutput.movie_id
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%blockbuster%')
    ))
ORDER BY 
    production_year DESC;
