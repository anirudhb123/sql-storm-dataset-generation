WITH top_movies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY
        mt.id, mt.title, mt.production_year
    HAVING
        COUNT(DISTINCT ci.person_id) > 10
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
company_movies AS (
    SELECT
        mc.movie_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COUNT(mc.company_id) AS company_count
    FROM
        movie_companies mc
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id, cn.name
),
cast_roles AS (
    SELECT
        ci.movie_id,
        rt.role,
        COUNT(ci.role_id) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, rt.role
),
ranked_movies AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        mk.keywords,
        COALESCE(cm.company_name, 'No Companies') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY tm.production_year ORDER BY tm.cast_count DESC) AS rank
    FROM
        top_movies tm
    LEFT JOIN
        movie_keywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN
        company_movies cm ON tm.movie_id = cm.movie_id
    WHERE
        tm.production_year IS NOT NULL
)

SELECT
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.keywords,
    rm.company_name,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top Performers' 
        ELSE 'Other Movies' 
    END AS movie_category,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)) AS total_actors_including_duplicates
FROM
    ranked_movies rm
WHERE
    rm.rank <= 10
AND
    EXISTS (
        SELECT 1
        FROM person_info pi
        WHERE pi.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
        AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Notable')
    )
ORDER BY
    rm.production_year DESC, rm.cast_count DESC;
