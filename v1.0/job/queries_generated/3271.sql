WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        R.role,
        R.nr_order,
        ROW_NUMBER() OVER (PARTITION BY T.id ORDER BY R.nr_order) AS actor_rank
    FROM 
        title T
    JOIN 
        cast_info R ON T.id = R.movie_id
    WHERE 
        T.production_year BETWEEN 2000 AND 2020
),
MovieKeywords AS (
    SELECT 
        M.movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords
    FROM 
        movie_keyword M 
    JOIN 
        keyword K ON M.keyword_id = K.id
    GROUP BY 
        M.movie_id
),
CompanyDetails AS (
    SELECT 
        MC.movie_id,
        C.name AS company_name,
        CT.kind AS company_type
    FROM 
        movie_companies MC
    JOIN 
        company_name C ON MC.company_id = C.id
    JOIN 
        company_type CT ON MC.company_type_id = CT.id
),
CompleteMovieInfo AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        MK.keywords,
        COALESCE(CD.company_name, 'Independent') AS company_name,
        COALESCE(CD.company_type, 'N/A') AS company_type,
        COUNT(DISTINCT RM.movie_id) OVER () AS total_movies
    FROM 
        RankedMovies RM
    LEFT JOIN 
        MovieKeywords MK ON RM.movie_id = MK.movie_id
    LEFT JOIN 
        CompanyDetails CD ON RM.movie_id = CD.movie_id
)
SELECT 
    C.movie_id,
    C.title,
    C.production_year,
    C.keywords,
    C.company_name,
    C.company_type,
    CASE 
        WHEN C.production_year < 2010 THEN 'Pre-2010'
        ELSE 'Post-2010'
    END AS era,
    CASE 
        WHEN C.company_name IS NULL THEN 'Company Not Present'
        ELSE 'Company Present'
    END AS company_presence,
    NTILE(5) OVER (ORDER BY C.production_year) AS year_quintile
FROM 
    CompleteMovieInfo C
WHERE 
    C.total_movies > 100 
ORDER BY 
    C.production_year DESC, C.title; 
