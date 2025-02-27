WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.id AS cast_id,
        c.nr_order,
        p.info AS person_info,
        pc.kind AS company_kind
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN person_info p ON a.person_id = p.person_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN comp_cast_type pc ON c.person_role_id = pc.id 
)
SELECT 
    md.aka_name,
    md.movie_title,
    md.production_year,
    COUNT(md.cast_id) AS total_cast,
    STRING_AGG(DISTINCT md.person_info, ', ') AS unique_person_infos,
    STRING_AGG(DISTINCT md.company_kind, ', ') AS associated_company_kinds
FROM MovieDetails md
GROUP BY md.aka_name, md.movie_title, md.production_year
ORDER BY md.production_year DESC, total_cast DESC
LIMIT 100;
