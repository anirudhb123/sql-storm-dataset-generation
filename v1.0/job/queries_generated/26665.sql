WITH movie_details AS (
    SELECT 
        T.id AS movie_id,
        T.title AS movie_title,
        T.production_year,
        K.keyword AS movie_keyword,
        COALESCE(CNT.company_count, 0) AS company_count,
        COUNT(DISTINCT CI.person_id) AS cast_count
    FROM 
        aka_title T
    LEFT JOIN 
        movie_keyword MK ON T.id = MK.movie_id
    LEFT JOIN 
        keyword K ON MK.keyword_id = K.id
    LEFT JOIN 
        complete_cast CC ON T.id = CC.movie_id
    LEFT JOIN 
        cast_info CI ON CC.subject_id = CI.id
    LEFT JOIN (
        SELECT 
            MC.movie_id,
            COUNT(DISTINCT MC.company_id) AS company_count
        FROM 
            movie_companies MC
        GROUP BY 
            MC.movie_id
    ) CNT ON T.id = CNT.movie_id
    GROUP BY 
        T.id, T.title, T.production_year, K.keyword, CNT.company_count
),

cast_details AS (
    SELECT 
        P.id AS person_id,
        P.name AS person_name,
        CI.movie_id,
        R.role AS person_role
    FROM 
        cast_info CI
    JOIN 
        aka_name P ON CI.person_id = P.person_id
    JOIN 
        role_type R ON CI.role_id = R.id
)

SELECT 
    MD.movie_id,
    MD.movie_title,
    MD.production_year,
    MD.movie_keyword,
    MD.company_count,
    MD.cast_count,
    STRING_AGG(CD.person_name || ' (' || CD.person_role || ')', ', ') AS cast_members
FROM 
    movie_details MD
LEFT JOIN 
    cast_details CD ON MD.movie_id = CD.movie_id
GROUP BY 
    MD.movie_id, MD.movie_title, MD.production_year, MD.movie_keyword, MD.company_count, MD.cast_count
ORDER BY 
    MD.production_year DESC, MD.movie_title;
