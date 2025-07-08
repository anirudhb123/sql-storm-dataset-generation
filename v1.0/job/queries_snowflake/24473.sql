
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.person_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM
        cast_info c
    JOIN
        (SELECT DISTINCT id, role FROM role_type) r ON c.person_role_id = r.id
    GROUP BY
        c.person_id, r.role
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT 
    na.person_id AS actor_id,
    na.name AS actor_name,
    rt.title,
    rt.production_year,
    COUNT(DISTINCT mk.keywords) AS keyword_count,
    COALESCE(SUM(ar.role_count), 0) AS total_roles,
    CASE WHEN COUNT(mk.keywords) > 0 THEN 'Has Keywords' ELSE 'No Keywords' END AS keyword_status
FROM
    aka_name na
LEFT JOIN
    cast_info ci ON na.person_id = ci.person_id
LEFT JOIN
    RankedTitles rt ON ci.movie_id = rt.title_id
LEFT JOIN
    MovieKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN
    ActorRoles ar ON na.person_id = ar.person_id
WHERE
    na.name IS NOT NULL
    AND na.md5sum IS NOT NULL
    AND rt.rank <= 5
GROUP BY
    na.person_id, na.name, rt.title, rt.production_year
HAVING
    COUNT(DISTINCT mk.keywords) < 3
ORDER BY
    rt.production_year DESC, na.name ASC
LIMIT 100 OFFSET 10;
