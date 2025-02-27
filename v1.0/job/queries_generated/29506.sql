WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS roles
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        pi.info AS biography
    FROM name p
    LEFT JOIN person_info pi ON p.id = pi.person_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    pd.name AS Person_Name,
    pd.biography AS Person_Biography,
    cd.companies AS Production_Companies,
    md.roles AS Role_Ids
FROM MovieDetails md
JOIN complete_cast cc ON md.title_id = cc.movie_id
JOIN PersonDetails pd ON cc.subject_id = pd.person_id
JOIN CompanyDetails cd ON md.title_id = cd.movie_id
WHERE md.production_year > 2000
ORDER BY md.production_year DESC, md.title;
