WITH movie_details AS (
    SELECT
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT c.role_id ORDER BY c.nr_order SEPARATOR ', ') AS role_ids,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM
        title t
    LEFT JOIN
        aka_title at ON t.id = at.movie_id
    LEFT JOIN
        aka_name ak ON at.id = ak.id
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id
),
person_details AS (
    SELECT
        n.name AS actor_name,
        p.info AS actor_info,
        p.person_id,
        p.note
    FROM
        name n
    JOIN
        cast_info ci ON n.imdb_id = ci.person_id
    JOIN
        person_info p ON ci.person_id = p.person_id
    WHERE
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography') 
)
SELECT
    md.title,
    md.production_year,
    md.aka_names,
    pd.actor_name,
    pd.actor_info,
    pd.note,
    md.companies,
    md.keywords
FROM
    movie_details md
JOIN
    person_details pd ON md.role_ids LIKE CONCAT('%', pd.person_id, '%')
WHERE
    md.production_year >= 2000
ORDER BY
    md.production_year DESC, md.title;
