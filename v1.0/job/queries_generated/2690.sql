WITH movie_ranking AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN ci.kind_id = 1 THEN 1 ELSE 0 END) AS lead_roles,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        role_type rt ON c.role_id = rt.id
    LEFT JOIN
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
keyword_aggregates AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    INNER JOIN
        keyword k ON mk.keyword_id = k.id
    INNER JOIN
        aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.movie_id
)
SELECT
    m.title,
    m.production_year,
    COALESCE(mr.actor_count, 0) AS actor_count,
    COALESCE(mr.lead_roles, 0) AS lead_roles,
    COALESCE(ka.keywords, 'No keywords') AS keywords
FROM
    aka_title m
LEFT JOIN
    movie_ranking mr ON m.title = mr.title AND m.production_year = mr.production_year
LEFT JOIN
    keyword_aggregates ka ON m.id = ka.movie_id
WHERE
    (mr.rank <= 10 OR mr.rank IS NULL)
ORDER BY
    m.production_year DESC,
    actor_count DESC;
