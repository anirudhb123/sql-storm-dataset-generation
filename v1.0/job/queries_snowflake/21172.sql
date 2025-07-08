
WITH recursive_name_roles AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        ct.kind,
        ROW_NUMBER() OVER (PARTITION BY ai.person_id ORDER BY ai.nr_order) AS role_rank
    FROM cast_info ai
    JOIN comp_cast_type ct ON ai.person_role_id = ct.id
    WHERE ct.kind IS NOT NULL
),

movie_titles AS (
    SELECT 
        at.id AS title_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM aka_title at
    LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
    GROUP BY at.id, at.title, at.production_year
),

person_keywords AS (
    SELECT 
        pi.person_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM person_info pi
    LEFT JOIN movie_keyword mk ON pi.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY pi.person_id
)

SELECT 
    rn.person_id,
    n.name AS person_name,
    mt.movie_title,
    mt.production_year,
    rn.role_rank,
    COALESCE(pk.keywords, 'No Keywords') AS keywords,
    mt.company_count
FROM recursive_name_roles rn
JOIN aka_name n ON rn.person_id = n.person_id
JOIN movie_titles mt ON rn.movie_id = mt.title_id
LEFT JOIN person_keywords pk ON rn.person_id = pk.person_id
WHERE (rn.role_rank = 1 OR rn.role_rank IS NULL) 
AND mt.production_year > 2000 
AND (pk.keywords IS NULL OR pk.keywords LIKE '%action%')
ORDER BY mt.production_year DESC, rn.role_rank ASC
LIMIT 50;
