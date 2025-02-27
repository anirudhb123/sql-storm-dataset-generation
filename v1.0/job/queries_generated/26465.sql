WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT a.id) AS actor_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kc ON mk.keyword_id = kc.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year > 2000
    GROUP BY
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT
        title_id,
        title,
        production_year,
        keyword_count,
        actor_count,
        RANK() OVER (ORDER BY keyword_count DESC, actor_count DESC) AS rank
    FROM
        RankedTitles
)
SELECT
    tt.rank,
    tt.title,
    tt.production_year,
    tt.keyword_count,
    tt.actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords
FROM
    TopTitles tt
LEFT JOIN
    cast_info ci ON tt.title_id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON tt.title_id = mk.movie_id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
WHERE
    tt.rank <= 10
GROUP BY
    tt.rank, tt.title, tt.production_year, tt.keyword_count, tt.actor_count
ORDER BY
    tt.rank;
