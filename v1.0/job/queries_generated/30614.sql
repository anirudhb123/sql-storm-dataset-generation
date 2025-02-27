WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        ActorHierarchy ah ON c.movie_id = ah.person_id
    WHERE
        ah.level < 5
),
MovieKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mt
    JOIN
        keyword k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
)
SELECT
    a.actor_name,
    STRING_AGG(DISTINCT tl.title, ', ') AS movie_titles,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    a.level AS hierarchy_level
FROM
    ActorHierarchy a
LEFT JOIN
    complete_cast cc ON a.person_id = cc.subject_id
LEFT JOIN
    aka_title tl ON cc.movie_id = tl.id
LEFT JOIN
    MovieKeywords mk ON tl.id = mk.movie_id
WHERE
    a.level <= 3 AND 
    (COALESCE(cc.status_id, 0) != 2 OR a.actor_name IS NOT NULL)
GROUP BY
    a.actor_name, mk.keywords, a.level
ORDER BY
    a.actor_name;
