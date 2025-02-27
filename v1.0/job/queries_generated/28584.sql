WITH MovieTitle AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM
        title t
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
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, a.name, r.role
),
CompanyInfo AS (
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
),
MovieDetails AS (
    SELECT
        mt.title_id,
        mt.title,
        mt.production_year,
        cd.actor_name,
        cd.role,
        ci.company_name,
        ci.company_type
    FROM
        MovieTitle mt
    LEFT JOIN
        CastDetails cd ON mt.title_id = cd.movie_id
    LEFT JOIN
        CompanyInfo ci ON mt.title_id = ci.movie_id
)

SELECT
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name || ' as ' || md.role, ', ') AS actor_roles,
    STRING_AGG(DISTINCT md.company_name || ' (' || md.company_type || ')', ', ') AS companies
FROM
    MovieDetails md
GROUP BY
    md.title_id, md.title, md.production_year
ORDER BY
    md.production_year DESC, md.title;
