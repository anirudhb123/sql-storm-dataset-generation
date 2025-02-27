
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopRankedMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.rank,
        rm.total_movies,
        (SELECT COUNT(*)
         FROM cast_info ci
         WHERE ci.movie_id = (SELECT m.id FROM aka_title m WHERE m.title = rm.title LIMIT 1)
        ) AS total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieCompaniesCTE AS (
    SELECT 
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cm ON mc.company_id = cm.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
DetailedMovieInfo AS (
    SELECT 
        tr.title, 
        tr.production_year, 
        tr.total_cast, 
        SUM(CASE WHEN mc.company_type = 'Production' THEN 1 ELSE 0 END) AS production_companies,
        SUM(CASE WHEN mc.company_type = 'Distributor' THEN 1 ELSE 0 END) AS distributor_companies
    FROM 
        TopRankedMovies tr
    LEFT JOIN 
        MovieCompaniesCTE mc ON tr.title = (SELECT at.title FROM aka_title at WHERE at.id = mc.movie_id)
    GROUP BY 
        tr.title, tr.production_year, tr.total_cast
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.total_cast,
    dmi.production_companies,
    dmi.distributor_companies,
    CASE 
        WHEN dmi.total_cast > 20 THEN 'Large Cast'
        WHEN dmi.total_cast IS NULL THEN 'No Cast Information'
        ELSE 'Small Cast' 
    END AS cast_size,
    COALESCE(NULLIF(dmi.production_companies, 0), NULL) AS non_zero_production_companies,
    CASE 
        WHEN dmi.production_year > 2000 THEN 'Modern'
        ELSE 'Classic'
    END AS movie_era
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_companies > 1 
    OR dmi.distributor_companies IS NOT NULL
ORDER BY 
    dmi.production_year DESC, dmi.title;
