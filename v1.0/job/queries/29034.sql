WITH TitleInfo AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),

ActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.production_year,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        a.id, a.name, t.production_year
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
),

CombinedDetails AS (
    SELECT
        ti.title_id,
        ti.title,
        ti.production_year,
        ad.actor_name,
        cd.company_name,
        cd.company_type,
        ti.keyword
    FROM
        TitleInfo ti
    LEFT JOIN
        ActorDetails ad ON ti.title_id = ad.movie_count
    LEFT JOIN
        CompanyDetails cd ON ti.title_id = cd.movie_id
)

SELECT
    cd.title_id,
    cd.title,
    cd.production_year,
    cd.actor_name,
    cd.company_name,
    cd.company_type,
    COUNT(cd.keyword) AS keyword_count
FROM
    CombinedDetails cd
GROUP BY
    cd.title_id, cd.title, cd.production_year, cd.actor_name, cd.company_name, cd.company_type
ORDER BY
    cd.production_year DESC, keyword_count DESC
LIMIT 100;
