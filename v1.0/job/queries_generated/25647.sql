WITH movie_keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
person_movie_roles AS (
    SELECT
        ci.movie_id,
        mi.info AS movie_info,
        COUNT(ci.role_id) AS role_count
    FROM
        cast_info ci
    JOIN
        person_info pi ON ci.person_id = pi.person_id
    JOIN
        movie_info mi ON ci.movie_id = mi.movie_id
    GROUP BY
        ci.movie_id, mi.info
),
company_movie_info AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
top_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        COALESCE(pm.role_count, 0) AS role_count,
        COUNT(DISTINCT cm.company_name) AS company_count
    FROM
        title t
    LEFT JOIN movie_keyword_count mkc ON t.id = mkc.movie_id
    LEFT JOIN person_movie_roles pm ON t.id = pm.movie_id
    LEFT JOIN company_movie_info cm ON t.id = cm.movie_id
    GROUP BY
        t.id, mkc.keyword_count, pm.role_count
    ORDER BY
        keyword_count DESC, role_count DESC, company_count DESC
    LIMIT 10
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.role_count,
    tm.company_count
FROM
    top_movies tm
JOIN
    aka_title at ON tm.movie_id = at.movie_id
JOIN
    aka_name an ON at.title ILIKE '%' || an.name || '%' 
WHERE
    an.name IS NOT NULL
ORDER BY
    tm.title;
