WITH RECURSIVE movies_with_cast AS (
    SELECT
        a.id AS aka_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM
        aka_name AS a
    JOIN
        cast_info AS c ON a.person_id = c.person_id
    JOIN
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE
        t.production_year >= 2000
)
SELECT
    movie_id,
    title,
    production_year,
    STRING_AGG(actor_name, ', ') AS actor_list
FROM
    movies_with_cast
GROUP BY
    movie_id, title, production_year
HAVING
    COUNT(*) > 3
ORDER BY
    production_year DESC;

WITH company_movie_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM
        movie_companies AS mc
    JOIN
        company_name AS co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    t.id AS title_id,
    t.title,
    COALESCE(cmc.company_count, 0) AS company_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count
FROM
    title AS t
LEFT JOIN
    company_movie_counts AS cmc ON t.id = cmc.movie_id
LEFT JOIN
    movie_keyword_counts AS mkc ON t.id = mkc.movie_id
WHERE
    t.production_year BETWEEN 2005 AND 2020
ORDER BY
    company_count DESC,
    keyword_count DESC;

WITH actor_movie_relations AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.id) AS roles_count
    FROM
        cast_info AS c
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id, a.name
),
top_actors AS (
    SELECT
        actor_name,
        SUM(roles_count) AS total_roles
    FROM
        actor_movie_relations
    GROUP BY
        actor_name
    HAVING
        SUM(roles_count) > 2
)
SELECT
    a.actor_name,
    COALESCE(m.title, 'No Title') AS movie_title,
    a.roles_count
FROM
    top_actors AS a
LEFT JOIN
    actor_movie_relations AS r ON a.actor_name = r.actor_name
LEFT JOIN
    aka_title AS m ON r.movie_id = m.movie_id
ORDER BY
    a.total_roles DESC, 
    movie_title;

SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(m_info.info::INTEGER) AS average_info_rating
FROM 
    title AS t
LEFT JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info AS m_info ON t.id = m_info.movie_id 
WHERE 
    m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'IMDB rating')
GROUP BY 
    t.title
HAVING 
    total_cast > 5 AND 
    average_info_rating IS NOT NULL
ORDER BY 
    average_info_rating DESC;
