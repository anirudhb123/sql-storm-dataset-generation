WITH movie_credits AS (
    SELECT
        a.id AS aka_id,
        t.title AS movie_title,
        t.production_year,
        c.person_role_id,
        p.name AS actor_name,
        row_number() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order
    FROM
        aka_title AS t
    JOIN
        cast_info AS c ON t.id = c.movie_id
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    JOIN
        name AS p ON a.person_id = p.imdb_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS m
    JOIN 
        keyword AS k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info AS mi
    WHERE 
        mi.note IS NOT NULL 
    GROUP BY 
        mi.movie_id
)
SELECT 
    mc.movie_title,
    mc.production_year,
    mc.actor_name,
    mc.cast_order,
    ks.keywords,
    is.info_details
FROM 
    movie_credits AS mc
LEFT JOIN 
    keyword_summary AS ks ON mc.aka_id = ks.movie_id
LEFT JOIN 
    info_summary AS is ON mc.aka_id = is.movie_id
ORDER BY 
    mc.production_year DESC, 
    mc.cast_order;
