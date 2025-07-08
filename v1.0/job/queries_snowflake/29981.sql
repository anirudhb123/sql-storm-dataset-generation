
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        rt.role AS actor_role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS role_rank
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    WHERE
        t.production_year >= 2000   
),

KeywordCount AS (
    SELECT
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        RankedMovies m ON mk.movie_id = m.movie_id
    GROUP BY
        m.movie_id
),

ComposedTitles AS (
    SELECT
        rm.movie_id,
        LISTAGG(DISTINCT rm.title, ' | ') WITHIN GROUP (ORDER BY rm.title) AS all_titles,
        LISTAGG(DISTINCT rm.actor_name, ', ') WITHIN GROUP (ORDER BY rm.actor_name) AS actor_names,
        kc.keyword_count
    FROM
        RankedMovies rm
    JOIN
        KeywordCount kc ON rm.movie_id = kc.movie_id
    WHERE
        rm.role_rank <= 3  
    GROUP BY
        rm.movie_id, kc.keyword_count
)

SELECT
    ct.movie_id,
    ct.all_titles,
    ct.actor_names,
    ct.keyword_count,
    CASE
        WHEN ct.keyword_count > 5 THEN 'Richly Tagged'
        WHEN ct.keyword_count BETWEEN 2 AND 5 THEN 'Moderately Tagged'
        ELSE 'Poorly Tagged'
    END AS tagging_quality
FROM
    ComposedTitles ct
ORDER BY
    ct.keyword_count DESC, ct.movie_id;
