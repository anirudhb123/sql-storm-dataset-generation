WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
CastDetails AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    rt.title,
    rt.production_year,
    rt.keyword,
    cd.actor_name,
    cd.role_name,
    co.company_name,
    co.company_type
FROM
    RankedTitles rt
JOIN
    CastDetails cd ON rt.title_id = cd.movie_id
JOIN
    CompanyDetails co ON rt.title_id = co.movie_id
WHERE
    rt.keyword_rank <= 3
ORDER BY
    rt.production_year DESC, rt.title;
