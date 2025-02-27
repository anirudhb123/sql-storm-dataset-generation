WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM title t
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        info.info AS additional_info
    FROM movie_companies mt
    JOIN company_name c ON mt.company_id = c.id
    JOIN company_type ct ON mt.company_type_id = ct.id
    LEFT JOIN movie_info info ON mt.movie_id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN r.role = 'leading' THEN 1 ELSE NULL END) AS leading_roles
    FROM cast_info ci
    JOIN role_type r ON ci.person_role_id = r.id
    GROUP BY ci.movie_id
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    md.company_name,
    md.company_type,
    cs.total_cast,
    cs.leading_roles
FROM RankedTitles rt
JOIN MovieDetails md ON rt.title_id = md.movie_id
JOIN CastStatistics cs ON rt.title_id = cs.movie_id
WHERE rt.title_rank <= 3 
ORDER BY rt.production_year DESC, LENGTH(rt.title) DESC;
