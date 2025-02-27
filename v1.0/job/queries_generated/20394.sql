WITH ranked_titles AS (
    SELECT
        a.id AS title_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        kt.keyword
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN
        keyword kt ON mk.keyword_id = kt.id
    WHERE
        a.production_year >= 2000
),
actor_role_summary AS (
    SELECT
        ci.person_id,
        r.role AS role_type,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.person_id, r.role
),
cast_info_with_titles AS (
    SELECT
        ci.*,
        aa.name AS actor_name,
        rt.role AS role_type
    FROM
        cast_info ci
    JOIN
        aka_name aa ON ci.person_id = aa.person_id
    LEFT JOIN
        role_type rt ON ci.role_id = rt.id
),
movie_info_sources AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_details
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    tt.title,
    tt.production_year,
    a.actor_name,
    ars.role_type,
    COALESCE(mis.info_details, 'No additional info') AS additional_info,
    CASE WHEN ars.movie_count > 5 THEN 'Frequent Actor'
         WHEN ars.movie_count BETWEEN 2 AND 5 THEN 'Occasional Actor'
         ELSE 'Rare Actor' END AS actor_frequentist_category,
    SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_company_count,
    COUNT(DISTINCT mc.company_id) AS total_companies_in_movies
FROM
    ranked_titles tt
JOIN
    cast_info_with_titles ciwt ON tt.title_id = ciwt.movie_id
JOIN
    actor_role_summary ars ON ciwt.person_id = ars.person_id
LEFT JOIN
    movie_companies mc ON tt.title_id = mc.movie_id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN
    movie_info_sources mis ON tt.title_id = mis.movie_id
GROUP BY
    tt.title_id, tt.title, tt.production_year, ciwt.actor_name, ars.role_type, mis.info_details
HAVING
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY
    tt.production_year DESC,
    actor_name;
