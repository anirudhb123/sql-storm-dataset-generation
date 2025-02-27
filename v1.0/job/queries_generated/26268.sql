WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_names,
        k.keyword AS keyword
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, k.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.id
),
info_details AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(DISTINCT i.info ORDER BY i.info SEPARATOR '; ') AS info_text
    FROM movie_info mi
    JOIN info_type i ON mi.info_type_id = i.id
    GROUP BY mi.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.cast_names,
    md.keyword,
    cd.company_names,
    cd.company_type,
    id.info_text
FROM movie_details md
LEFT JOIN company_details cd ON md.id = cd.movie_id
LEFT JOIN info_details id ON md.id = id.movie_id
WHERE md.production_year BETWEEN 2000 AND 2023
ORDER BY md.production_year DESC, md.title;
