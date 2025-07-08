
WITH RecursiveMovieInfo AS (
    SELECT 
        T.title AS movie_title, 
        C.name AS company_name, 
        CC.kind AS company_type, 
        CONCAT(AK.name, ' as ', R.role) AS cast_info, 
        T.production_year 
    FROM 
        aka_title T
    JOIN 
        movie_companies MC ON T.id = MC.movie_id
    JOIN 
        company_name C ON MC.company_id = C.id
    JOIN 
        company_type CC ON MC.company_type_id = CC.id
    JOIN 
        complete_cast CC2 ON T.id = CC2.movie_id
    JOIN 
        cast_info CA ON CC2.subject_id = CA.person_id
    JOIN 
        role_type R ON CA.role_id = R.id
    JOIN 
        aka_name AK ON CA.person_id = AK.person_id
    WHERE 
        T.production_year BETWEEN 1990 AND 2020
),
KeywordInfo AS (
    SELECT 
        RMI.movie_title, 
        RMI.company_name, 
        RMI.company_type, 
        RMI.cast_info,
        RMI.production_year,
        K.keyword 
    FROM 
        RecursiveMovieInfo RMI
    JOIN 
        movie_keyword MK ON RMI.movie_title = (SELECT title FROM title WHERE id = MK.movie_id)
    JOIN 
        keyword K ON MK.keyword_id = K.id
),
FinalOutput AS (
    SELECT 
        movie_title,
        LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS companies,
        LISTAGG(DISTINCT company_type, ', ') WITHIN GROUP (ORDER BY company_type) AS types,
        LISTAGG(DISTINCT cast_info, '; ') WITHIN GROUP (ORDER BY cast_info) AS cast_details,
        MIN(production_year) AS first_production_year
    FROM 
        KeywordInfo
    GROUP BY 
        movie_title
)
SELECT 
    movie_title, 
    companies, 
    types, 
    cast_details, 
    first_production_year
FROM 
    FinalOutput
ORDER BY 
    first_production_year DESC;
