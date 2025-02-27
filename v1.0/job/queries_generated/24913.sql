WITH RecursiveMovieCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mk.keyword) AS keyword_rank,
        COUNT(*) OVER (PARTITION BY mt.id) AS total_keywords
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE
        mt.production_year IS NOT NULL
),
ActorRoleCTE AS (
    SELECT
        ci.movie_id,
        an.name AS actor_name,
        ci.nr_order,
        rt.role AS actor_role,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
MovieWithCompanyCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        company.name AS production_company,
        MAX(mct.kind) AS company_type
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN
        company_name company ON mc.company_id = company.id
    LEFT JOIN
        company_type mct ON mc.company_type_id = mct.id
    GROUP BY
        mt.id, company.name
),
CombinedResults AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        r.keyword,
        a.actor_name,
        a.actor_role,
        m.production_company,
        m.company_type,
        CASE 
            WHEN r.keyword IS NULL THEN 'No Keywords'
            WHEN a.actor_name IS NULL THEN 'No Actors'
            ELSE CONCAT(a.actor_name, ' - ', a.actor_role)
        END AS actor_role_info
    FROM
        RecursiveMovieCTE r
    LEFT JOIN
        ActorRoleCTE a ON r.movie_id = a.movie_id
    LEFT JOIN
        MovieWithCompanyCTE m ON r.movie_id = m.movie_id
    WHERE
        r.keyword_rank = 1 AND m.company_type IS NOT NULL
)
SELECT
    movie_id,
    title,
    production_year,
    keyword,
    actor_name,
    actor_role,
    production_company,
    company_type,
    actor_role_info
FROM
    CombinedResults
WHERE
    production_year > 2000 AND (keyword NOT LIKE '%action%' OR actor_name IS NULL)
ORDER BY
    production_year DESC, title ASC
LIMIT 100;
