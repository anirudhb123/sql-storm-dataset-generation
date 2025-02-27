WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id, m.title, m.production_year
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    rm.keywords
FROM
    ranked_movies rm
WHERE
    rm.rank <= 5
ORDER BY
    rm.production_year DESC, rm.cast_count DESC;
