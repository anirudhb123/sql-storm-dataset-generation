WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.movie_id,
           mt.title,
           mt.production_year,
           mct.kind AS company_type,
           1 AS level
    FROM aka_title mt
    JOIN movie_companies mc ON mt.movie_id = mc.movie_id
    JOIN company_type mct ON mc.company_type_id = mct.id
    WHERE mct.kind ILIKE '%Production%'
    
    UNION ALL
    
    SELECT mt.movie_id,
           mt.title,
           mt.production_year,
           mct.kind AS company_type,
           mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    JOIN company_type mct ON mc.company_type_id = mct.id
    WHERE mct.kind ILIKE '%Studio%'
),
actors_stats AS (
    SELECT ak.person_id,
           ak.name,
           COUNT(DISTINCT ci.movie_id) AS movies_count,
           STRING_AGG(DISTINCT at.title, ', ') AS movies_titles
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    GROUP BY ak.person_id, ak.name
),
high_volume_actors AS (
    SELECT person_id,
           name,
           movies_count,
           movies_titles
    FROM actors_stats
    WHERE movies_count > 5
),
ranked_movies AS (
    SELECT mt.title,
           COUNT(mc.movie_id) AS companies_count,
           RANK() OVER (ORDER BY COUNT(mc.movie_id) DESC) AS company_rank
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.movie_id = mc.movie_id
    GROUP BY mt.title
)
SELECT mh.title AS movie_title,
       mh.production_year,
       mh.company_type,
       hva.name AS actor_name,
       hv.movies_count,
       rm.companies_count,
       rm.company_rank
FROM movie_hierarchy mh
LEFT JOIN high_volume_actors hv ON hv.movies_titles LIKE '%' || mh.title || '%'
LEFT JOIN ranked_movies rm ON rm.title = mh.title
WHERE mh.level = 1
  AND (rm.companies_count IS NULL OR rm.companies_count < 3)
  AND COALESCE(hv.movies_count, 0) > 2
ORDER BY mh.production_year DESC, rm.company_rank, hv.movies_count DESC;
