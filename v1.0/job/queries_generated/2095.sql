WITH RankedMovies AS (
    SELECT 
        T.title,
        T.production_year,
        COUNT(A.id) AS actor_count,
        RANK() OVER (PARTITION BY T.production_year ORDER BY COUNT(A.id) DESC) AS rank_within_year
    FROM 
        aka_title T
    LEFT JOIN 
        cast_info C ON T.id = C.movie_id
    LEFT JOIN 
        aka_name A ON C.person_id = A.person_id
    GROUP BY 
        T.id, T.title, T.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
MovieDetails AS (
    SELECT 
        TM.title,
        TM.production_year,
        STRING_AGG(DISTINCT CN.name, ', ') AS companies,
        COUNT(DISTINCT MK.keyword) AS keyword_count
    FROM 
        TopMovies TM
    LEFT JOIN 
        movie_companies MC ON MC.movie_id = (
            SELECT 
                movie_id 
            FROM 
                complete_cast CC 
            WHERE 
                CC.subject_id = (
                    SELECT 
                        id 
                    FROM 
                        title 
                    WHERE 
                        title = TM.title 
                        AND production_year = TM.production_year
                )
            LIMIT 1
        )
    LEFT JOIN 
        company_name CN ON MC.company_id = CN.id
    LEFT JOIN 
        movie_keyword MK ON MK.movie_id = (
            SELECT 
                id 
            FROM 
                title 
            WHERE 
                title = TM.title 
                AND production_year = TM.production_year
        )
    GROUP BY 
        TM.title, TM.production_year
)
SELECT 
    MD.title,
    MD.production_year,
    COALESCE(MD.companies, 'No companies involved') AS companies_involved,
    MD.keyword_count
FROM 
    MovieDetails MD
ORDER BY 
    MD.production_year DESC, 
    MD.keyword_count DESC;
