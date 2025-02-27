
WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        R.role,
        COUNT(CI.person_id) AS cast_count,
        RANK() OVER (PARTITION BY T.id ORDER BY COUNT(CI.person_id) DESC) AS role_rank
    FROM 
        aka_title T
    JOIN 
        cast_info CI ON T.id = CI.movie_id
    LEFT JOIN 
        role_type R ON CI.role_id = R.id
    WHERE 
        T.production_year >= 2000
    GROUP BY 
        T.id, T.title, T.production_year, R.role
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        role_rank = 1
),
MovieDetails AS (
    SELECT 
        TM.movie_id,
        TM.title,
        TM.production_year,
        STRING_AGG(DISTINCT CN.name, ', ') AS company_names
    FROM 
        TopMovies TM
    LEFT JOIN 
        movie_companies MC ON TM.movie_id = MC.movie_id
    LEFT JOIN 
        company_name CN ON MC.company_id = CN.id
    GROUP BY 
        TM.movie_id, TM.title, TM.production_year
),
KeywordStatistics AS (
    SELECT 
        MK.movie_id,
        COUNT(K.id) AS keyword_count
    FROM 
        movie_keyword MK
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
),
MovieKeywords AS (
    SELECT 
        MD.movie_id,
        MD.title,
        MD.production_year,
        MD.company_names,
        COALESCE(KS.keyword_count, 0) AS keyword_count
    FROM 
        MovieDetails MD
    LEFT JOIN 
        KeywordStatistics KS ON MD.movie_id = KS.movie_id
)
SELECT 
    M.title,
    M.production_year,
    M.company_names,
    M.keyword_count,
    CASE 
        WHEN M.keyword_count > 5 THEN 'High'
        WHEN M.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_category
FROM 
    MovieKeywords M
WHERE 
    M.production_year IN (SELECT DISTINCT production_year FROM aka_title WHERE production_year IS NOT NULL)
    AND M.keyword_count IS NOT NULL
ORDER BY 
    M.production_year DESC, 
    M.keyword_count DESC 
LIMIT 10;
