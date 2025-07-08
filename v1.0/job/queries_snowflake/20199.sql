
WITH RECURSIVE movie_chain AS (
    SELECT
        mc.movie_id,
        COUNT(*) AS depth,
        LISTAGG(DISTINCT t.title, ' -> ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM
        movie_link AS ml
    JOIN 
        movie_companies AS mc ON mc.movie_id = ml.movie_id
    JOIN 
        title AS t ON t.id = mc.movie_id
    WHERE
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel')
    GROUP BY
        mc.movie_id
),
ranked_movies AS (
    SELECT
        m.id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        RANK() OVER (ORDER BY COUNT(c.person_id) DESC) AS cast_rank
    FROM
        aka_title AS m
    LEFT JOIN 
        cast_info AS c ON c.movie_id = m.movie_id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year
),
combined_results AS (
    SELECT
        r.title,
        r.production_year,
        COALESCE(CAST(m.depth AS INTEGER), 0) AS sequel_depth,
        COALESCE(r.year_rank, 0) AS year_rank,
        COALESCE(r.cast_rank, 0) AS casting_rank,
        r.title || ' (' || COALESCE(m.movie_titles, 'No sequels') || ')' AS movie_info
    FROM
        ranked_movies AS r
    LEFT JOIN 
        movie_chain AS m ON r.id = m.movie_id
)
SELECT
    cr.title,
    cr.production_year,
    cr.sequel_depth,
    cr.year_rank,
    cr.casting_rank,
    cr.movie_info
FROM
    combined_results AS cr
ORDER BY
    cr.production_year DESC,
    cr.sequel_depth DESC,
    cr.casting_rank ASC
LIMIT 50;
