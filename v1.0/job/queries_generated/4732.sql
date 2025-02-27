WITH movie_roles AS (
    SELECT
        c.movie_id,
        c.person_id,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
),
movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor') THEN 1 ELSE 0 END), 0) AS distributor_count,
        COUNT(DISTINCT mkw.keyword_id) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        movie_keyword mkw ON m.id = mkw.movie_id
    GROUP BY
        m.id
)
SELECT
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT nr.name, ', ') AS actors,
    md.distributor_count,
    md.keyword_count,
    COALESCE(AVG(CASE WHEN mr.role = 'Director' THEN 1 END), 0) AS director_count,
    COUNT(DISTINCT case when nr.gender = 'F' and mr.role_order IS NOT NULL then nr.id end) AS female_actors
FROM
    movie_details md
LEFT JOIN
    movie_roles mr ON md.movie_id = mr.movie_id
LEFT JOIN
    aka_name nr ON mr.person_id = nr.person_id
WHERE
    md.production_year > 2000
GROUP BY
    md.title, md.production_year
HAVING
    COUNT(DISTINCT nr.id) > 0
ORDER BY
    md.production_year DESC, md.title;
