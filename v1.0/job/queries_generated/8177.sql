WITH MovieDetails AS (
    SELECT t.id AS movie_id, t.title, t.production_year, 
           GROUP_CONCAT(DISTINCT c.kind_id) AS genre_ids,
           COALESCE(m.info, 'No Info Available') AS movie_info,
           GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM aka_title t
    LEFT JOIN movie_info m ON t.id = m.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN role_type r ON ci.role_id = r.id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id, t.title, t.production_year, m.info
),
ActorDetails AS (
    SELECT a.name, COUNT(ci.movie_id) AS movie_count,
           AVG(YEAR(t.production_year) - YEAR(ci.nr_order)) AS avg_year_diff
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    WHERE a.name IS NOT NULL
    GROUP BY a.name
)
SELECT md.movie_id, md.title, md.production_year, md.movie_info, 
       ad.name AS actor_name, ad.movie_count, ad.avg_year_diff, 
       md.keywords
FROM MovieDetails md
JOIN ActorDetails ad ON md.movie_id = ad.movie_count
ORDER BY md.production_year DESC, ad.movie_count DESC
LIMIT 50;
