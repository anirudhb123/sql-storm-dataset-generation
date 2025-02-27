WITH ranked_movies AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY RANDOM()) AS random_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL AND
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%' OR kind LIKE '%Comedy%')
),
actor_stats AS (
    SELECT
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        AVG(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM
        aka_name ak
    LEFT JOIN
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN
        role_type c ON ci.role_id = c.id
    GROUP BY
        ak.person_id, ak.name
),
movie_keywords AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
filtered_movies AS (
    SELECT
        r.title,
        r.production_year,
        ms.total_movies,
        mk.keywords
    FROM
        ranked_movies r
    JOIN
        actor_stats ms ON ms.total_movies > 5
    LEFT JOIN
        movie_keywords mk ON r.id = mk.movie_id
    WHERE
        r.random_rank <= 20 AND
        (r.kind_id IS NULL OR r.kind_id <> 2) -- Assuming 2 is a kind we want to exclude
)
SELECT
    fm.title,
    fm.production_year,
    fm.total_movies,
    COALESCE(fm.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN fm.production_year < 2000 THEN 'Classic'
        WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT ci.person_id) AS unique_actors
FROM
    filtered_movies fm
LEFT JOIN
    cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = fm.title)
GROUP BY
    fm.title, fm.production_year, fm.total_movies, fm.keywords
ORDER BY
    fm.production_year DESC,
    fm.total_movies DESC;
