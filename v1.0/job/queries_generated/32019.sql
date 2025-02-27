WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, a.name AS actor_name, 0 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IS NOT NULL
      AND a.name IS NOT NULL
    UNION ALL
    SELECT ch.person_id, ah.actor_name, ah.level + 1
    FROM cast_info ch
    JOIN ActorHierarchy ah ON ch.movie_id = ah.movie_id
)
, MovieAvgRatings AS (
    SELECT
        m.title,
        AVG(ri.rating) AS avg_rating
    FROM
        title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN movie_info_idx ri ON mi.id = ri.info_type_id AND mi.info_type_id = 1
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.title
)
, PopularKeywords AS (
    SELECT
        mk.keyword_id,
        COUNT(mk.movie_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.keyword_id
    HAVING
        COUNT(mk.movie_id) > 5
), CompanyRoleInfo AS (
    SELECT
        ci.role_id,
        COUNT(DISTINCT cm.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        cast_info ci
    JOIN movie_companies mc ON ci.movie_id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        ci.role_id
)
SELECT
    ah.actor_name,
    mh.avg_rating,
    pki.keyword_count,
    cri.company_count,
    cri.company_names
FROM
    ActorHierarchy ah
JOIN MovieAvgRatings mh ON mh.title = (
        SELECT 
            m.title 
        FROM title m 
        JOIN cast_info c 
        ON m.id = c.movie_id
        WHERE c.person_id = ah.person_id 
        LIMIT 1
    )
LEFT JOIN PopularKeywords pki ON EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id IN (
            SELECT movie_id 
            FROM cast_info 
            WHERE person_id = ah.person_id
        )
        AND mk.keyword_id = pki.keyword_id
    )
LEFT JOIN CompanyRoleInfo cri ON cri.role_id = (
    SELECT role_id 
    FROM cast_info 
    WHERE person_id = ah.person_id 
    LIMIT 1
)
WHERE
    ah.level = 0
ORDER BY
    mh.avg_rating DESC NULLS LAST,
    pki.keyword_count DESC,
    cri.company_count DESC;
