
WITH movie_stats AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        MIN(mci.id) AS first_company_id,
        MAX(mci.id) AS last_company_id,
        COALESCE(NULLIF(AVG(mi.info_type_id), 0), -1) AS avg_info_type_id
    FROM
        aka_title mt
    LEFT JOIN
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        movie_companies mci ON mt.id = mci.movie_id
    LEFT JOIN
        movie_info mi ON mt.id = mi.movie_id
    WHERE
        mt.production_year IS NOT NULL
    GROUP BY
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.num_cast_members,
        ROW_NUMBER() OVER (ORDER BY ms.num_cast_members DESC) AS rn
    FROM
        movie_stats ms
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    (SELECT COUNT(*) FROM movie_link ml WHERE ml.movie_id = tm.movie_id) AS num_links,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM movie_companies mc 
     JOIN company_name cn ON mc.company_id = cn.id 
     WHERE mc.movie_id = tm.movie_id) AS company_names,
    CASE 
        WHEN tm.num_cast_members > 10 THEN 'Large Cast'
        WHEN tm.num_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM
    top_movies tm
WHERE
    tm.rn <= 10
ORDER BY
    tm.num_cast_members DESC;
