WITH movie_cast AS (
    SELECT 
        A.title AS movie_title,
        GROUP_CONCAT(CN.name, ', ') AS cast_names,
        MT.production_year,
        CT.kind AS company_type,
        MK.keyword AS keywords
    FROM aka_title A
    JOIN cast_info C ON A.id = C.movie_id
    JOIN aka_name CN ON C.person_id = CN.person_id
    JOIN movie_companies MC ON A.id = MC.movie_id
    JOIN company_type CT ON MC.company_type_id = CT.id
    JOIN movie_keyword MK ON A.id = MK.movie_id
    GROUP BY 
        A.title, MT.production_year, CT.kind
),
movie_details AS (
    SELECT 
        MC.movie_id,
        MI.info,
        IT.info AS info_type
    FROM movie_info MI
    JOIN info_type IT ON MI.info_type_id = IT.id
    JOIN movie_companies MC ON MC.movie_id = MI.movie_id
    WHERE IT.info LIKE '%Box Office%'
)

SELECT 
    MC.movie_title,
    MC.cast_names,
    MC.production_year,
    MD.info AS box_office_info,
    MD.info_type
FROM movie_cast MC
LEFT JOIN movie_details MD ON MC.movie_id = MD.movie_id
WHERE MC.production_year >= 2000
ORDER BY MC.production_year DESC, MC.movie_title;

