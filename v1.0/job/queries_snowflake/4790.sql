
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, rt.role
),
MoviesWithCompany AS (
    SELECT
        m.id AS movie_id,
        m.title,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        m.id, m.title
),
ActorDetails AS (
    SELECT
        ak.person_id,
        ak.name,
        COALESCE(pi.info, 'No information') AS info,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ak
    LEFT JOIN
        person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    LEFT JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.person_id, ak.name, pi.info
)
SELECT
    t.title,
    t.production_year,
    r.role,
    r.role_count,
    m.companies,
    ad.name AS actor_name,
    ad.info,
    ad.movie_count,
    CASE 
        WHEN ad.movie_count > 0 THEN 'Active Actor' 
        ELSE 'Inactive Actor' 
    END AS actor_status
FROM
    RankedTitles t
JOIN
    CastRoles r ON t.title_id = r.movie_id
JOIN
    MoviesWithCompany m ON t.title_id = m.movie_id
JOIN
    cast_info ci ON t.title_id = ci.movie_id
JOIN
    ActorDetails ad ON ci.person_id = ad.person_id
WHERE
    t.year_rank = 1
    AND t.production_year >= 2000
    AND m.companies IS NOT NULL
ORDER BY
    t.production_year DESC, r.role_count DESC;
