WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE
        c.movie_id IN (
            SELECT id FROM aka_title WHERE production_year = 2023
        )
    
    UNION ALL
    
    SELECT
        c.person_id,
        ah.actor_name,
        ah.level + 1
    FROM
        ActorHierarchy ah
    JOIN cast_info c ON ah.person_id = c.person_id
    WHERE
        c.movie_id IN (
            SELECT linked_movie_id FROM movie_link 
            WHERE link_type_id IN (
                SELECT id FROM link_type WHERE link = 'franchise'
            )
        )
)
SELECT
    a.actor_name,
    COUNT(*) AS total_movies,
    AVG(m.production_year) AS avg_year,
    STRING_AGG(DISTINCT ti.title, ', ') AS titles,
    MAX(m.production_year) AS latest_movie_year
FROM
    ActorHierarchy a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title m ON c.movie_id = m.movie_id
LEFT JOIN title ti ON ti.id = m.id
GROUP BY
    a.actor_name
HAVING
    COUNT(*) > 5 AND
    MAX(m.production_year) >= 2020
ORDER BY
    total_movies DESC;

-- Count movies with a specific keyword and add NULL checks for optional joins
WITH KeywordMovies AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword LIKE '%action%'
)

SELECT
    a.actor_name,
    km.keyword,
    COUNT(DISTINCT c.movie_id) AS movie_count
FROM
    aka_name a
JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN KeywordMovies km ON c.movie_id = km.movie_id
WHERE
    a.name_pcode_nf IS NOT NULL
GROUP BY
    a.actor_name, km.keyword
HAVING
    COUNT(DISTINCT c.movie_id) > 3
ORDER BY
    movie_count DESC;
This SQL query performs several advanced operations, including recursive CTEs to build a hierarchy of actors involved in movies produced in 2023. It incorporates outer joins, null checks, aggregates over groups, and a filtering mechanism for the results based on predefined conditions involving the production year and movie keywords.
