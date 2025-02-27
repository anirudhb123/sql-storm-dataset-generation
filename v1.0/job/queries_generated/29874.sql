WITH MovieRoles AS (
    SELECT
        c.movie_id,
        p.name AS person_name,
        r.role AS role_name,
        COUNT(c.person_id) AS role_count
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, p.name, r.role
),
KeywordDistribution AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompanyDetails AS (
    SELECT DISTINCT
        m.movie_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies m
    JOIN
        company_name cn ON m.company_id = cn.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
)
SELECT
    t.title AS movie_title,
    t.production_year,
    mr.person_name,
    mr.role_name,
    mr.role_count,
    kd.keywords,
    cd.company_name,
    cd.company_type
FROM
    title t
LEFT JOIN
    MovieRoles mr ON t.id = mr.movie_id
LEFT JOIN
    KeywordDistribution kd ON t.id = kd.movie_id
LEFT JOIN
    CompanyDetails cd ON t.id = cd.movie_id
WHERE
    t.production_year BETWEEN 2000 AND 2023
ORDER BY
    t.production_year DESC, mr.role_count DESC, t.title;
