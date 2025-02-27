WITH ranked_movies AS (
    SELECT
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'MPAA Rating')
        AND t.production_year IS NOT NULL
        AND ak.name IS NOT NULL
),
movie_keywords AS (
    SELECT
        t.id AS movie_id,
        k.keyword
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
movies_with_keywords AS (
    SELECT
        rm.title,
        rm.production_year,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_keywords mk ON rm.title = mk.title AND rm.production_year = mk.production_year
    GROUP BY
        rm.title, rm.production_year
)
SELECT
    m.title,
    m.production_year,
    COALESCE(m.keywords, 'No keywords available') AS keywords,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = m.id) AS num_cast_members
FROM
    movies_with_keywords m
WHERE
    m.rn <= 10
ORDER BY
    m.production_year DESC, m.title;
