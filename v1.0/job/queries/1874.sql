
WITH MovieStats AS (
    SELECT 
        T.title AS movie_title,
        T.production_year,
        COALESCE(SUM(CASE WHEN C.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast,
        COUNT(DISTINCT MC.company_id) AS total_companies,
        STRING_AGG(DISTINCT A.name, ', ') AS actors
    FROM 
        aka_title T
    LEFT JOIN 
        cast_info C ON T.id = C.movie_id
    LEFT JOIN 
        complete_cast CC ON CC.movie_id = T.id
    LEFT JOIN 
        movie_companies MC ON MC.movie_id = T.id
    LEFT JOIN 
        aka_name A ON A.person_id = C.person_id
    WHERE 
        T.production_year IS NOT NULL
    GROUP BY 
        T.title, T.production_year
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        total_companies,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, total_companies DESC) AS rank
    FROM 
        MovieStats
),
FilteredMovies AS (
    SELECT 
        RM.movie_title,
        RM.production_year,
        RM.total_cast,
        RM.total_companies,
        CASE 
            WHEN RM.total_cast > 0 THEN 'Active Cast' 
            ELSE 'No Cast' 
        END AS cast_status
    FROM 
        RankedMovies RM
    WHERE 
        RM.production_year > 2000
)
SELECT 
    FM.movie_title,
    FM.production_year,
    FM.total_cast,
    FM.total_companies,
    FM.cast_status
FROM 
    FilteredMovies FM
WHERE 
    EXISTS (SELECT 1 FROM role_type RT WHERE RT.role = 'Actor')
ORDER BY 
    FM.production_year DESC, FM.total_cast DESC
LIMIT 20;
