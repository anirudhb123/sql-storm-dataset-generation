WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
        JOIN title t ON ak.movie_id = t.id
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
CriticalCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS rn,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS total_companies
    FROM 
        movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
CombinedMovieData AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.notes_count,
        md.aka_names,
        COALESCE(cc.company_name, 'No Company') AS primary_company,
        COALESCE(cc.company_type, 'Unknown') AS company_type,
        cc.rn,
        cc.total_companies
    FROM 
        MovieDetails md
    LEFT JOIN CriticalCompanies cc ON md.movie_id = cc.movie_id AND cc.rn = 1
),
FilteredData AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count > 5 THEN 'Large Cast' 
            WHEN cast_count BETWEEN 3 AND 5 THEN 'Medium Cast' 
            ELSE 'Small Cast' 
        END AS cast_size,
        CASE 
            WHEN company_type LIKE '%Production%' THEN 'Production Company'
            ELSE 'Other Company Type'
        END AS company_category
    FROM 
        CombinedMovieData
)
SELECT 
    title, 
    production_year, 
    aka_names, 
    cast_size, 
    company_category,
    AVG(notes_count) OVER (PARTITION BY production_year) AS avg_notes_per_movie,
    COUNT(*) FILTER (WHERE production_year < 2000) AS pre_2000_movies
FROM 
    FilteredData
WHERE 
    production_year IS NOT NULL
    AND (NOT (aka_names IS NULL OR aka_names = '') OR cast_count > 0)
ORDER BY 
    production_year DESC, 
    cast_count DESC;
