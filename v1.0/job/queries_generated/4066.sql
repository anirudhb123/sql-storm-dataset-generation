WITH RecursiveMovieTitles AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        m.id,
        CONCAT(m.title, ' (Episode ', m.season_nr, '.', m.episode_nr, ')') AS title,
        m.production_year,
        m.kind_id,
        level + 1
    FROM
        aka_title m
    JOIN
        RecursiveMovieTitles r ON m.episode_of_id = r.movie_id
)
SELECT
    p.id AS person_id,
    a.name AS actor_name,
    COUNT(DISTINCT rc.movie_id) AS movies_count,
    STRING_AGG(DISTINCT CONCAT(rmt.title, ' (', rmt.production_year, ')'), '; ') AS movie_titles,
    CASE
        WHEN COUNT(DISTINCT rc.movie_id) > 5 THEN 'Popular'
        WHEN COUNT(DISTINCT rc.movie_id) BETWEEN 1 AND 5 THEN 'Moderate'
        ELSE 'Newcomer'
    END AS actor_status
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    RecursiveMovieTitles rmt ON ci.movie_id = rmt.movie_id
JOIN
    person_info p ON a.person_id = p.person_id
LEFT JOIN
    complete_cast cc ON cc.movie_id = ci.movie_id
WHERE
    p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
    AND rmt.production_year < 2023
GROUP BY
    p.id, a.name
HAVING
    COUNT(DISTINCT rc.movie_id) > 1
ORDER BY
    movies_count DESC, actor_name ASC;
