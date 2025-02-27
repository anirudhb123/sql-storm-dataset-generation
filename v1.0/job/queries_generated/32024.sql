WITH RECURSIVE movie_cast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        c.nr_order AS cast_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_position
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
),
company_details AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
filtered_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        (SELECT COUNT(1) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = m.id) AS keyword_count
    FROM
        title m
    WHERE
        m.production_year >= 2000
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
ranked_cast AS (
    SELECT
        mc.movie_id,
        mc.actor_name,
        mc.cast_order,
        cd.company_count,
        RANK() OVER (PARTITION BY mc.movie_id ORDER BY mc.cast_order) AS rank_order
    FROM
        movie_cast mc
    JOIN
        company_details cd ON mc.movie_id = cd.movie_id
),
notable_movies AS (
    SELECT
        fm.movie_id,
        fm.title,
        fm.production_year,
        rc.actor_name,
        rc.rank_order,
        COALESCE(cd.company_name, 'Independent') AS company_name
    FROM
        filtered_movies fm
    LEFT JOIN
        ranked_cast rc ON fm.movie_id = rc.movie_id
    LEFT JOIN
        company_details cd ON fm.movie_id = cd.movie_id
    WHERE
        rc.rank_order <= 3 OR rc.rank_order IS NULL
)
SELECT
    nm.movie_id,
    nm.title,
    nm.production_year,
    STRING_AGG(DISTINCT nm.actor_name, ', ') AS actors,
    MAX(CASE WHEN nm.company_type IS NOT NULL THEN nm.company_name ELSE 'Unknown' END) AS production_company,
    COUNT(DISTINCT nm.company_name) AS distinct_company_count
FROM
    notable_movies nm
GROUP BY
    nm.movie_id, nm.title, nm.production_year
HAVING
    COUNT(DISTINCT nm.actor_name) > 2
ORDER BY
    nm.production_year DESC, nm.title;
