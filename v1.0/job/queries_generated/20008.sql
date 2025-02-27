WITH movie_details AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        c.kind AS comp_kind,
        COUNT(DISTINCT m.company_id) AS total_companies,
        SUM(CASE 
                WHEN m.note IS NOT NULL THEN 1 
                ELSE 0 
            END) AS companies_with_notes,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS row_num
    FROM
        aka_title a
    LEFT JOIN
        movie_companies m ON a.id = m.movie_id
    LEFT JOIN
        company_type c ON m.company_type_id = c.id
    GROUP BY
        a.id, a.title, a.production_year, c.kind
),
actor_movies AS (
    SELECT
        ak.name AS actor_name,
        t.title AS movie_title,
        COUNT(DISTINCT ci.person_role_id) AS role_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.id
    GROUP BY
        ak.name, t.title
),
keyword_details AS (
    SELECT
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM
        keyword k
    LEFT JOIN
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY
        k.keyword
    HAVING
        COUNT(mk.movie_id) > 5
),
final_output AS (
    SELECT
        md.movie_title,
        md.production_year,
        md.comp_kind,
        md.total_companies,
        md.companies_with_notes,
        am.actor_name,
        am.role_count,
        kd.keyword,
        kd.keyword_count
    FROM
        movie_details md
    FULL OUTER JOIN
        actor_movies am ON md.movie_title = am.movie_title
    FULL OUTER JOIN
        keyword_details kd ON md.movie_title LIKE '%' || kd.keyword || '%'
    WHERE
        (md.total_companies IS NOT NULL OR am.role_count IS NOT NULL OR kd.keyword_count IS NOT NULL)
        AND md.production_year >= 2000
)
SELECT
    movie_title,
    production_year,
    comp_kind,
    total_companies,
    companies_with_notes,
    actor_name,
    role_count,
    keyword,
    keyword_count
FROM
    final_output
ORDER BY 
    production_year DESC,
    total_companies DESC,
    role_count DESC
FETCH FIRST 100 ROWS ONLY;
