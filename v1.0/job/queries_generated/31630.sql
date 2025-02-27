WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.id AS cast_id,
        c.movie_id,
        a.person_id,
        a.name AS actor_name,
        1 AS depth
    FROM
        cast_info c
    INNER JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name IS NOT NULL

    UNION ALL

    SELECT
        ch.cast_id,
        ch.movie_id,
        a.person_id,
        a.name AS actor_name,
        h.depth + 1
    FROM
        cast_info ch
    INNER JOIN
        aka_name a ON ch.person_id = a.person_id
    INNER JOIN
        ActorHierarchy h ON ch.movie_id = h.movie_id
    WHERE
        h.depth < 2 AND ch.id <> h.cast_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT ah.actor_name, ', ') AS actor_names,
    mk.keywords,
    COALESCE(mci.note, 'N/A') AS company_notes,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ah.person_id) DESC) AS actor_rank,
    COUNT(DISTINCT ah.person_id) AS total_actors
FROM
    title t
LEFT JOIN
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN
    ActorHierarchy ah ON cc.subject_id = ah.cast_id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    movie_info mi ON mi.movie_id = t.id
LEFT JOIN
    MovieKeywords mk ON mk.movie_id = t.id
LEFT JOIN
    movie_info_idx mii ON mii.movie_id = t.id AND mii.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
LEFT JOIN
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN
    title lt ON ml.linked_movie_id = lt.id
LEFT JOIN
    info_type it ON mii.info_type_id = it.id
LEFT JOIN
    movie_keyword mk2 ON mk2.movie_id = t.id
WHERE
    t.production_year >= 2000
    AND (cn.country_code IS NULL OR cn.country_code != 'USA')
    AND EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = t.id AND ci.person_role_id IS NOT NULL)
GROUP BY 
    t.id, t.title, t.production_year, mk.keywords, mci.note
HAVING
    COUNT(DISTINCT ah.person_id) >= 3
ORDER BY 
    actor_rank ASC, total_actors DESC;
