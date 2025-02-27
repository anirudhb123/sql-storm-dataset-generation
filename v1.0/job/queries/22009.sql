
WITH RECURSIVE movies_with_cast AS (
    SELECT
        m.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT c.role_id) AS total_roles
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.person_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        title m ON t.id = m.id
    WHERE
        t.production_year BETWEEN 1990 AND 2020
    GROUP BY
        m.id, t.title
),
movie_info_aggregates AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS info_type_count,
        STRING_AGG(info, '; ') AS info_details
    FROM
        movie_info
    WHERE
        note IS NULL
    GROUP BY
        movie_id
),
movie_keyword_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM
        movie_keyword
    GROUP BY
        movie_id
),
ranked_movies AS (
    SELECT
        mwc.movie_id,
        mwc.title,
        mwc.actor_names,
        mwc.total_roles,
        COALESCE(mia.info_type_count, 0) AS info_count,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY mwc.total_roles DESC, mia.info_type_count DESC) AS rank
    FROM
        movies_with_cast mwc
    LEFT JOIN
        movie_info_aggregates mia ON mwc.movie_id = mia.movie_id
    LEFT JOIN
        movie_keyword_counts mkc ON mwc.movie_id = mkc.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.actor_names,
    rm.total_roles,
    rm.info_count,
    rm.keyword_count,
    CASE
        WHEN rm.info_count >= 5 AND rm.keyword_count > 3 THEN 'Highly Informative'
        WHEN rm.info_count >= 0 AND rm.keyword_count <= 3 THEN 'Moderately Informative'
        ELSE 'Low Informative'
    END AS informativity_category,
    (SELECT COUNT(*) FROM ranked_movies r WHERE r.keyword_count = rm.keyword_count) AS keyword_rank_position
FROM
    ranked_movies rm
WHERE
    rm.rank <= 100
    AND EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = rm.movie_id AND ci.nr_order IS NOT NULL
        GROUP BY ci.movie_id
        HAVING COUNT(DISTINCT ci.nr_order) > 1
    )
ORDER BY
    rm.info_count DESC, keyword_rank_position ASC;
