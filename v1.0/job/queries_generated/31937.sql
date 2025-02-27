WITH Recursive_CTE AS (
    SELECT
        p.id AS person_id,
        p.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY c.nr_order) AS role_order
    FROM
        name p
    LEFT JOIN
        cast_info c ON p.id = c.person_id
    WHERE
        c.movie_id IS NOT NULL
),
Filtered_Movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
Company_Info AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, co.name, ct.kind
)
SELECT
    f.movie_id,
    f.title AS movie_title,
    f.production_year,
    f.keyword_count,
    ci.company_name,
    ci.company_type,
    ci.company_count,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = f.movie_id) AS total_cast,
    COALESCE(SUM(CASE WHEN r.role_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles
FROM
    Filtered_Movies f
LEFT JOIN
    Company_Info ci ON f.movie_id = ci.movie_id
LEFT JOIN
    Recursive_CTE r ON f.movie_id = r.person_id
WHERE
    f.production_year >= 2000
    AND (f.keyword_count > 5 OR ci.company_type = 'Distributor')
GROUP BY
    f.movie_id, f.title, f.production_year, ci.company_name, ci.company_type, ci.company_count
ORDER BY
    f.production_year DESC,
    f.keyword_count DESC,
    ci.company_count DESC;
