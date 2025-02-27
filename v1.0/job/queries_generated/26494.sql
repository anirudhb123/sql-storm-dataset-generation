WITH
    RankedTitles AS (
        SELECT
            a.id AS aka_id,
            t.id AS title_id,
            t.title,
            t.production_year,
            t.kind_id,
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
        FROM
            aka_title t
        JOIN
            movie_keyword mk ON t.id = mk.movie_id
        JOIN
            keyword k ON mk.keyword_id = k.id
        WHERE
            k.keyword ILIKE '%action%'
    ),
    
    ActorRoles AS (
        SELECT
            c.person_id,
            r.role,
            COUNT(c.id) AS role_count
        FROM
            cast_info c
        JOIN
            role_type r ON c.role_id = r.id
        GROUP BY
            c.person_id,
            r.role
    ),
    
    MovieCompanyInfo AS (
        SELECT
            mc.movie_id,
            GROUP_CONCAT(DISTINCT cn.name) AS companies,
            GROUP_CONCAT(DISTINCT ct.kind) AS company_types
        FROM
            movie_companies mc
        JOIN
            company_name cn ON mc.company_id = cn.id
        JOIN
            company_type ct ON mc.company_type_id = ct.id
        GROUP BY
            mc.movie_id
    )

SELECT
    a.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    ar.role,
    mci.companies,
    mci.company_types
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    RankedTitles rt ON ci.movie_id = rt.title_id
JOIN
    ActorRoles ar ON ci.person_id = ar.person_id
JOIN
    MovieCompanyInfo mci ON mci.movie_id = rt.title_id
WHERE
    rt.title_rank <= 5
ORDER BY
    rt.production_year DESC, a.name;
