
WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT kc.id) AS keyword_count
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    WHERE mt.production_year BETWEEN 2000 AND 2023
    GROUP BY mt.id, mt.title, mt.production_year
),
director_movies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS directors
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'director'
    GROUP BY mc.movie_id
),
performance_ranking AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        dm.directors,
        RANK() OVER (ORDER BY md.production_year DESC, md.keyword_count DESC) AS ranking
    FROM movie_details md
    LEFT JOIN director_movies dm ON md.movie_id = dm.movie_id
)
SELECT 
    title,
    production_year,
    actors,
    directors,
    ranking
FROM performance_ranking
WHERE ranking <= 10
  AND (directors IS NOT NULL OR actors IS NOT NULL)
ORDER BY production_year DESC, ranking;
