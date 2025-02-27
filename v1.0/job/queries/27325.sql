
WITH movie_data AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ',') AS aliases,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN
        cast_info c ON c.movie_id = t.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.aliases, 'No aliases available') AS aliases,
    COALESCE(md.keywords, 'No keywords available') AS keywords,
    md.company_count,
    md.cast_count,
    CASE
        WHEN md.cast_count > 10 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    movie_data md
WHERE 
    md.company_count > 0
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
