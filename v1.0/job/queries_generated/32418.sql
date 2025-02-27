WITH RECURSIVE actor_hierarchy AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        c.person_id,
        1 AS depth
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name IS NOT NULL

    UNION ALL

    SELECT
        c.movie_id,
        a.name AS actor_name,
        c.person_id,
        ah.depth + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE
        a.name IS NOT NULL AND depth < 5
),
movie_details AS (
    SELECT
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ah.actor_name ORDER BY ah.depth) AS actors,
        m.note AS company_type_note,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN
        actor_hierarchy ah ON t.id = ah.movie_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, m.note
)
SELECT
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No Actors Available') AS actors,
    COUNT(DISTINCT mc.company_id) AS company_count,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 10 THEN 'Highly Tagged'
        WHEN md.keyword_count > 5 THEN 'Moderately Tagged'
        ELSE 'Low Tagged'
    END AS tagging_level
FROM
    movie_details md
LEFT JOIN
    movie_companies mc ON md.movie_id = mc.movie_id
GROUP BY
    md.title, md.production_year, md.actors, md.keyword_count
ORDER BY
    md.production_year DESC, md.title;
