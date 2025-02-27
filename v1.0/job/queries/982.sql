
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT
        m.movie_id,
        c.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM
        complete_cast m
    JOIN
        cast_info c ON m.movie_id = c.movie_id
    JOIN
        aka_name ak ON c.person_id = ak.person_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
company_details AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    rm.title,
    rm.production_year,
    STRING_AGG(DISTINCT mc.company_name, ', ') AS companies,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_name) AS company_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT CONCAT(ac.actor_name, ' (Rank: ', ac.actor_rank, ')')) AS actor_list
FROM
    ranked_movies rm
LEFT JOIN
    movie_cast ac ON rm.movie_id = ac.movie_id
LEFT JOIN
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    company_details mc ON rm.movie_id = mc.movie_id
WHERE
    rm.rank_within_year <= 5
GROUP BY
    rm.title, rm.production_year
HAVING
    COUNT(DISTINCT ac.person_id) > 1
ORDER BY
    rm.production_year DESC, rm.title;
