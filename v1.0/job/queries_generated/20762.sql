WITH RECURSIVE movie_chain AS (
    SELECT
        m.id AS movie_id,
        1 AS depth,
        t.title AS title,
        CASE
            WHEN t.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(t.production_year AS text)
        END AS production_year,
        NULL AS parent_movie_id
    FROM
        aka_title t
    JOIN
        title m ON m.id = t.movie_id
    WHERE
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        mc.linked_movie_id,
        mc.depth + 1,
        t.title,
        CASE
            WHEN t.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(t.production_year AS text)
        END AS production_year,
        mc.movie_id
    FROM
        movie_link mc
    JOIN
        title t ON mc.linked_movie_id = t.id
    JOIN
        movie_chain mc2 ON mc2.movie_id = mc.movie_id
)

SELECT
    CASE
        WHEN depth % 2 = 0 THEN 'Even depth: ' || title
        ELSE 'Odd depth: ' || title
    END AS movie_info,
    COUNT(DISTINCT mc.movie_id) AS related_movies_count,
    MAX(production_year) AS latest_year
FROM
    movie_chain mc
LEFT JOIN
    aka_name an ON mc.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM name WHERE name ILIKE '%Smith%'))
GROUP BY
    movie_info,
    depth
HAVING
    COUNT(DISTINCT mc.movie_id) > 2
ORDER BY
    latest_year DESC, 
    related_movies_count DESC;

WITH successful_movies AS (
    SELECT
        m.id,
        m.title,
        COUNT(DISTINCT c.person_id) AS successful_cast_count
    FROM
        title m
    JOIN
        cast_info c ON c.movie_id = m.id
    WHERE
        c.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%Starring%')
    GROUP BY
        m.id, m.title
    HAVING
        COUNT(DISTINCT c.person_id) > 1
)
SELECT 
    sm.title AS movie_title,
    sm.successful_cast_count,
    CASE
        WHEN sm.successful_cast_count > 5 THEN 'Star-studded Cast'
        ELSE 'Regular Cast'
    END AS cast_quality,
    json_agg(an.name) AS co_stars
FROM 
    successful_movies sm
LEFT JOIN 
    cast_info ci ON sm.id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    sm.title, sm.successful_cast_count
ORDER BY 
    successful_cast_count DESC;

SELECT
    a.name,
    COUNT(DISTINCT mi.movie_id) AS movies_involved,
    SUM(CASE WHEN m.production_year IS NULL THEN 0 ELSE 1 END) AS non_null_year_count
FROM
    aka_name a
LEFT JOIN
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN
    movie_info mi ON mi.movie_id = mc.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%award%')
LEFT JOIN
    title m ON m.id = ci.movie_id
WHERE
    a.name IS NOT NULL
GROUP BY
    a.name
HAVING 
    COUNT(DISTINCT mi.movie_id) > 0
ORDER BY
    movies_involved DESC
LIMIT 10;
