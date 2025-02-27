WITH recursive title_ranks AS (
    SELECT
        t.id AS title_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank,
        COUNT(*) OVER () AS total_titles
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ca.movie_id,
        ca.person_id,
        COALESCE(ca.note, 'No Role') AS role_note,
        COALESCE(na.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_order
    FROM
        cast_info ca
    LEFT JOIN aka_name na ON ca.person_id = na.person_id
),
keyword_list AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
    FROM
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_status AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS total_cast,
        COUNT(DISTINCT c.person_id) AS unique_actors
    FROM 
        complete_cast c
    GROUP BY 
        c.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(rd.role, 'Unknown Role') AS role,
    cd.actor_name,
    cd.role_note,
    kl.all_keywords,
    ms.total_cast,
    ms.unique_actors,
    (CASE
        WHEN ms.unique_actors > 0 THEN (ms.total_cast * 1.0 / ms.unique_actors)
        ELSE NULL
    END) AS actor_cast_ratio,
    (CASE
        WHEN tr.year_rank < 5 THEN 'Top 5 in Year'
        ELSE 'Not in Top 5'
    END) AS title_ranking
FROM
    title t
LEFT JOIN title_ranks tr ON t.id = tr.title_id
LEFT JOIN cast_details cd ON t.id = cd.movie_id
LEFT JOIN keyword_list kl ON t.id = kl.movie_id
LEFT JOIN movie_status ms ON t.id = ms.movie_id
LEFT JOIN role_type rd ON cd.role_id = rd.id
WHERE
    t.production_year IS NOT NULL
    AND (t.production_year BETWEEN 1990 AND 2023)
    AND (cd.actor_order IS NULL OR cd.actor_order <= 3 OR cd.role_note LIKE '%lead%')
ORDER BY 
    t.production_year DESC,
    actor_cast_ratio DESC NULLS LAST,
    title_ranking,
    t.title;
