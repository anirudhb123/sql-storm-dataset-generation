WITH RECURSIVE title_hierarchy AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level,
        ARRAY[t.title] AS title_path
    FROM
        title t
    WHERE
        t.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id AS title_id,
        e.title,
        e.production_year,
        e.kind_id,
        th.level + 1,
        th.title_path || e.title
    FROM
        title e
    INNER JOIN title_hierarchy th ON e.episode_of_id = th.title_id
),
cast_ranks AS (
    SELECT
        c.movie_id,
        c.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM
        cast_info c
),
movie_details AS (
    SELECT
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        (SELECT COUNT(DISTINCT mk.keyword) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = c.movie_id) AS keyword_count
    FROM
        title t
    JOIN aka_title ak ON ak.movie_id = t.id
    JOIN cast_ranks c ON c.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON ct.id = mc.company_type_id
    WHERE
        t.production_year >= 2000
        AND ak.name IS NOT NULL
        AND EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = t.id AND mi.info LIKE '%Oscar%')
),
ranked_movies AS (
    SELECT
        md.title,
        md.production_year,
        md.actor_name,
        md.company_type,
        md.keyword_count,
        RANK() OVER (ORDER BY md.keyword_count DESC) AS movie_rank
    FROM
        movie_details md
),
final_output AS (
    SELECT
        r.title,
        r.production_year,
        r.actor_name,
        r.company_type,
        r.keyword_count,
        CASE
            WHEN r.movie_rank <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS rank_group
    FROM
        ranked_movies r
)
SELECT
    COALESCE(f.title, 'Unknown Title') AS movie_title,
    COALESCE(f.production_year::text, 'N/A') AS year,
    COALESCE(f.actor_name, 'No Actor') AS lead_actor,
    COALESCE(f.company_type, 'Independent') AS production_company,
    CASE 
        WHEN f.keyword_count IS NULL THEN 'No Keywords'
        ELSE f.keyword_count::text
    END AS keyword_details,
    COUNT(*) OVER () AS total_movies
FROM
    final_output f
ORDER BY
    f.production_year DESC, f.keyword_count DESC
LIMIT 100 OFFSET 0;
