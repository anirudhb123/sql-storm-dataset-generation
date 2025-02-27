WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),
CompanyTitles AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mt.title,
    mt.production_year,
    ctr.total_cast,
    ct.company_name,
    ct.company_type,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = mt.title_id 
       AND cc.status_id IS NULL) AS null_status_count,
    CASE 
        WHEN mt.keyword_rank IS NOT NULL THEN 'Keyword Available'
        ELSE 'No Keywords'
    END AS keyword_status
FROM MovieTitles mt
JOIN CastInfoWithRoles ctr ON mt.title_id = ctr.movie_id
LEFT JOIN CompanyTitles ct ON mt.title_id = ct.movie_id
WHERE mt.production_year >= 2000
ORDER BY mt.production_year DESC, ctr.total_cast DESC
LIMIT 50;
