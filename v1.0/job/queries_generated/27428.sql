WITH ranked_movies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM
        aka_title a
    LEFT JOIN
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
movie_details AS (
    SELECT
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        rm.keyword_count,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Blockbuster'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Moderate'
            ELSE 'Low Cast'
        END AS cast_category
    FROM ranked_movies rm
)
SELECT
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    md.keyword_count,
    md.cast_category
FROM
    movie_details md
WHERE
    md.production_year >= 2000
ORDER BY
    md.cast_category DESC, md.production_year DESC, md.movie_title;
