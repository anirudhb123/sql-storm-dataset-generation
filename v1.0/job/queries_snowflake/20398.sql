WITH movie_summary AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(MAX(k.keyword), 'No Keywords') AS keyword_summary,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ca.nr_order IS NOT NULL THEN ca.nr_order ELSE 0 END) AS avg_order,
        COUNT(CASE WHEN EXISTS (
            SELECT 1
            FROM company_name cn
            JOIN movie_companies mc ON mc.movie_id = m.id
            WHERE mc.company_id = cn.id AND cn.country_code = 'USA'
            ) THEN 1 END) AS usa_company_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN
        cast_info c ON c.movie_id = m.id
    LEFT JOIN
        complete_cast cc ON cc.movie_id = m.id
    LEFT JOIN
        (SELECT
            person_id,
            movie_id,
            ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY nr_order) AS nr_order
        FROM
            cast_info
        WHERE
            role_id IN (SELECT id FROM role_type WHERE role LIKE '%Lead%')) ca ON ca.movie_id = m.id
    GROUP BY
        m.id, m.title
),

ranked_movies AS (
    SELECT
        ms.movie_id,
        ms.movie_title,
        ms.keyword_summary,
        ms.total_cast,
        ms.avg_order,
        RANK() OVER (ORDER BY ms.total_cast DESC, ms.avg_order ASC) AS rank
    FROM
        movie_summary ms
)

SELECT
    rm.movie_id,
    rm.movie_title,
    rm.keyword_summary,
    rm.total_cast,
    rm.avg_order,
    CASE 
        WHEN rm.total_cast >= 5 THEN 'Popular'
        WHEN rm.total_cast BETWEEN 1 AND 4 THEN 'Moderate'
        ELSE 'Not Popular'
    END AS popularity_category,
    COALESCE(NULLIF(rm.keyword_summary, 'No Keywords'), 'Untitled') AS adjusted_keyword
FROM
    ranked_movies rm
WHERE
    rm.rank <= 10
ORDER BY
    rm.rank ASC, rm.avg_order DESC;

