WITH RecursiveMovieLinks AS (
    SELECT ml.movie_id, ml.linked_movie_id, ml.link_type_id, 1 AS depth
    FROM movie_link ml
    WHERE ml.movie_id IS NOT NULL
    UNION ALL
    SELECT ml.movie_id, ml.linked_movie_id, ml.link_type_id, rml.depth + 1
    FROM movie_link ml
    JOIN RecursiveMovieLinks rml ON ml.movie_id = rml.linked_movie_id
    WHERE rml.depth < 5
),
MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN aka_name a ON a.person_id = ci.person_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    WHERE t.production_year > 1990
      AND (c.country_code IS NULL OR c.country_code != 'USA')
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
),
FinalMetrics AS (
    SELECT 
        md.title_id,
        md.movie_title,
        md.production_year,
        md.actor_name,
        kd.keywords,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.movie_title) AS row_num,
        CASE 
            WHEN md.actor_rank IS NOT NULL THEN 'Has actors'
            ELSE 'No actors'
        END AS actor_status,
        CASE 
            WHEN kd.keyword_count > 5 THEN 'Highly tagged'
            WHEN kd.keyword_count BETWEEN 3 AND 5 THEN 'Moderately tagged'
            ELSE 'Sparsely tagged'
        END AS keyword_status
    FROM MovieDetails md
    LEFT JOIN KeywordDetails kd ON md.title_id = kd.movie_id
)
SELECT 
    title_id,
    movie_title,
    production_year,
    actor_name,
    keywords,
    row_num,
    actor_status,
    keyword_status
FROM FinalMetrics
WHERE production_year BETWEEN 2000 AND 2020
  AND (keywords IS NULL OR keywords NOT LIKE '%action%')
ORDER BY production_year, movie_title
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
