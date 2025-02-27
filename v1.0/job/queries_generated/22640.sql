WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
actors AS (
    SELECT
        ca.person_id,
        p.name AS actor_name,
        RANK() OVER (ORDER BY COUNT(ca.movie_id) DESC) AS actor_rank
    FROM
        cast_info ca
    JOIN
        aka_name p ON ca.person_id = p.person_id
    GROUP BY
        ca.person_id, p.name
),
movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(i.info, 'No additional info') AS additional_info
    FROM
        aka_title m
    LEFT JOIN
        movie_info i ON m.id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1)
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(a.actor_name, 'Unknown Actor') AS actor_name,
    rm.year_count,
    md.additional_info,
    CASE 
        WHEN rm.year_count > 5 THEN 'Popular Year'
        WHEN rm.year_count = 1 THEN 'Cult Classic'
        ELSE 'Standard Release' 
    END AS release_category,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM
    ranked_movies rm
LEFT JOIN
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN
    actors a ON ci.person_id = a.person_id
LEFT JOIN
    movie_details md ON rm.movie_id = md.movie_id
WHERE
    rm.rn <= 3 AND (md.additional_info IS NOT NULL OR a.actor_rank <= 10)
GROUP BY
    rm.movie_id, rm.title, rm.production_year, a.actor_name, rm.year_count, md.additional_info
ORDER BY
    rm.production_year DESC, rm.title;
