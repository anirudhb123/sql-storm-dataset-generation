WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS acted_in_titles
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN RankedMovies r ON ci.movie_id = r.movie_id
    LEFT JOIN aka_title t ON r.movie_id = t.id
    WHERE a.name IS NOT NULL
    GROUP BY a.id, a.name
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.name) AS company_rank
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
    WHERE c.country_code IS NOT NULL
),
ActorCompany AS (
    SELECT 
        ai.actor_id,
        ai.name AS actor_name,
        cd.company_name,
        cd.company_type,
        cd.company_rank
    FROM ActorInfo ai
    LEFT JOIN cast_info ci ON ai.actor_id = ci.person_id
    JOIN complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN CompanyDetails cd ON cc.movie_id = cd.movie_id
)
SELECT 
    ac.actor_name,
    ac.company_name, 
    ac.company_type,
    COUNT(DISTINCT ac.company_name) OVER (PARTITION BY ac.actor_name) AS distinct_company_count,
    CASE 
        WHEN COUNT(DISTINCT ac.company_name) OVER (PARTITION BY ac.actor_name) > 5 THEN 'Frequent Collaborator'
        ELSE 'Occasional Collaborator'
    END AS collaboration_status,
    MAX(ROUND(COALESCE(ai.movie_count, 0) / NULLIF(RANK() OVER (ORDER BY ac.actor_name), 0), 2)) AS movies_per_rank
FROM ActorCompany ac
LEFT JOIN ActorInfo ai ON ac.actor_id = ai.actor_id
WHERE ac.company_type IS NOT NULL 
AND ac.company_type NOT LIKE '%production%' 
ORDER BY ac.actor_name, ac.company_rank;
