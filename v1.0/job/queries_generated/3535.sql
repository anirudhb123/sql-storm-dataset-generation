WITH RecursiveRole AS (
    SELECT ci.person_id, 
           ct.kind AS role, 
           COUNT(*) AS role_count
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.person_id, ct.kind
), TitleCTE AS (
    SELECT t.id AS title_id, 
           t.title, 
           t.production_year, 
           COALESCE(AVG(mi.info::numeric), 0) AS avg_rating,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS yearly_rank
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
), CastDetails AS (
    SELECT pn.name AS person_name,
           tt.title,
           tt.production_year,
           rr.role,
           ROW_NUMBER() OVER (PARTITION BY tt.title ORDER BY rr.role_count DESC) AS role_rank
    FROM RecursiveRole rr
    JOIN cast_info ci ON rr.person_id = ci.person_id
    JOIN title tt ON ci.movie_id = tt.id
    JOIN aka_name pn ON ci.person_id = pn.person_id
)
SELECT td.title, 
       td.production_year, 
       cd.person_name, 
       cd.role, 
       td.avg_rating
FROM TitleCTE td
JOIN CastDetails cd ON td.title = cd.title AND td.production_year = cd.production_year
WHERE cd.role_rank <= 3
ORDER BY td.production_year DESC, td.avg_rating DESC, cd.role;
