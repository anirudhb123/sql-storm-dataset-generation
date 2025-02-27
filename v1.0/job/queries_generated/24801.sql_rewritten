WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY T.title) AS rn,
        COUNT(*) OVER (PARTITION BY T.production_year) AS movie_count
    FROM
        aka_title T
    WHERE
        T.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND T.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year
    FROM 
        RankedMovies RM
    WHERE 
        RM.rn <= 5 
),
MovieDetails AS (
    SELECT 
        TM.movie_id,
        TM.title,
        TM.production_year,
        COUNT(DISTINCT CI.person_id) AS actor_count,
        STRING_AGG(DISTINCT AN.name, ', ') AS actor_names,
        COUNT(DISTINCT MI.info) FILTER (WHERE I.info = 'Box Office') AS box_office_count
    FROM 
        TopMovies TM
    LEFT JOIN 
        cast_info CI ON TM.movie_id = CI.movie_id
    LEFT JOIN 
        aka_name AN ON CI.person_id = AN.person_id
    LEFT JOIN 
        movie_info MI ON TM.movie_id = MI.movie_id
    LEFT JOIN 
        info_type I ON MI.info_type_id = I.id
    GROUP BY 
        TM.movie_id, TM.title, TM.production_year
),
CompanyMovies AS (
    SELECT 
        MC.movie_id,
        COUNT(DISTINCT CN.name) AS company_count,
        STRING_AGG(DISTINCT CN.name, ', ') AS company_names
    FROM 
        movie_companies MC
    JOIN 
        company_name CN ON MC.company_id = CN.id
    GROUP BY 
        MC.movie_id
)
SELECT 
    MD.movie_id,
    MD.title,
    MD.production_year,
    MD.actor_count,
    MD.actor_names,
    COALESCE(CM.company_count, 0) AS company_count,
    COALESCE(CM.company_names, 'None') AS company_names,
    MD.box_office_count
FROM 
    MovieDetails MD
FULL OUTER JOIN 
    CompanyMovies CM ON MD.movie_id = CM.movie_id
WHERE 
    (MD.actor_count > 0 OR CM.company_count IS NULL)
    AND (MD.box_office_count IS NULL OR MD.box_office_count > 0)
ORDER BY 
    MD.production_year DESC,
    MD.title ASC;