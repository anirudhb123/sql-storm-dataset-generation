
WITH RecentMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        KIND.kind AS movie_kind
    FROM 
        title
    JOIN 
        kind_type AS KIND ON title.kind_id = KIND.id
    WHERE 
        title.production_year >= 2020
), 
CastAndRoles AS (
    SELECT 
        C.movie_id,
        A.name AS actor_name,
        R.role AS role_type
    FROM 
        cast_info AS C
    JOIN 
        aka_name AS A ON C.person_id = A.person_id
    JOIN 
        role_type AS R ON C.role_id = R.id
), 
KeywordMovies AS (
    SELECT 
        MK.movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS MK
    JOIN 
        keyword AS K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
), 
CompanyMovies AS (
    SELECT 
        MC.movie_id,
        STRING_AGG(CN.name, ', ') AS companies
    FROM 
        movie_companies AS MC
    JOIN 
        company_name AS CN ON MC.company_id = CN.id
    GROUP BY 
        MC.movie_id
)
SELECT 
    RM.movie_title,
    RM.production_year,
    RM.movie_kind,
    CAR.actor_name,
    CAR.role_type,
    KM.keywords,
    CM.companies
FROM 
    RecentMovies AS RM
LEFT JOIN 
    CastAndRoles AS CAR ON RM.movie_id = CAR.movie_id
LEFT JOIN 
    KeywordMovies AS KM ON RM.movie_id = KM.movie_id
LEFT JOIN 
    CompanyMovies AS CM ON RM.movie_id = CM.movie_id
ORDER BY 
    RM.production_year DESC, 
    RM.movie_title;
