WITH movie_details AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM
        title t
    LEFT JOIN
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        cast_info ca ON t.id = ca.movie_id
    LEFT JOIN
        role_type r ON ca.role_id = r.id
    WHERE
        t.production_year > 1990
    GROUP BY
        t.id
),
person_details AS (
    SELECT
        p.id AS person_id,
        p.name AS person_name,
        GROUP_CONCAT(DISTINCT pi.info) AS personal_info,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names
    FROM
        name p
    LEFT JOIN
        person_info pi ON p.id = pi.person_id
    LEFT JOIN
        aka_name ak ON p.id = ak.person_id
    GROUP BY
        p.id
)
SELECT
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.companies,
    pd.person_name,
    pd.personal_info,
    pd.aka_names AS person_aka_names,
    RANK() OVER (ORDER BY md.production_year DESC) AS movie_rank
FROM
    movie_details md
JOIN
    cast_info ca ON md.movie_title = (SELECT m.title FROM title m WHERE m.id = ca.movie_id)
JOIN
    person_details pd ON ca.person_id = pd.person_id
ORDER BY
    md.production_year DESC, pd.person_name;
