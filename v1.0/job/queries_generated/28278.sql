WITH MovieDetails AS (
    SELECT 
        A.id AS movie_id,
        A.title AS movie_title,
        A.production_year,
        A.kind_id,
        M.name AS company_name,
        N.name AS person_name,
        GROUP_CONCAT(DISTINCT C.note) AS cast_notes,
        GROUP_CONCAT(DISTINCT K.keyword) AS keywords
    FROM 
        aka_title A
    JOIN 
        movie_companies MC ON A.id = MC.movie_id
    JOIN 
        company_name M ON MC.company_id = M.id
    JOIN 
        movie_info MI ON A.id = MI.movie_id
    JOIN 
        cast_info CI ON A.id = CI.movie_id
    JOIN 
        aka_name N ON CI.person_id = N.person_id
    LEFT JOIN 
        movie_keyword MK ON A.id = MK.movie_id
    LEFT JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE 
        MI.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary') 
        AND A.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        A.id, A.title, A.production_year, A.kind_id, M.name, N.name
)
SELECT 
    MD.movie_title,
    MD.production_year,
    MD.company_name,
    MD.person_name,
    MD.cast_notes,
    MD.keywords
FROM 
    MovieDetails MD
WHERE 
    MD.keywords LIKE '%action%'
ORDER BY 
    MD.production_year DESC, MD.movie_title;
