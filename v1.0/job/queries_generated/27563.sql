WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT
        ka.person_id,
        ka.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name ka
    JOIN
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY
        ka.person_id, ka.name
),
movie_keyword_details AS (
    SELECT
        mk.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
highly_rated_movies AS (
    SELECT 
        m.id AS movie_id, 
        f.info AS rating_info
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info LIKE '%rating%'
        AND m.note IS NULL
)
SELECT
    tt.title,
    tt.production_year,
    ai.actor_name,
    ai.movie_count,
    mk.keywords,
    hr.rating_info
FROM
    ranked_titles tt
JOIN
    cast_info ci ON tt.title_id = ci.movie_id
JOIN
    actor_info ai ON ci.person_id = ai.person_id
LEFT JOIN
    movie_keyword_details mk ON tt.title_id = mk.movie_id
LEFT JOIN
    highly_rated_movies hr ON tt.title_id = hr.movie_id
WHERE
    tt.rn <= 3  -- Limit to top 3 titles per year
ORDER BY 
    tt.production_year DESC, 
    tt.title;
