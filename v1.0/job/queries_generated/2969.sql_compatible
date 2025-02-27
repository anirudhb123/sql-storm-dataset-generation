
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY t.id, t.title, t.production_year
),
high_rated_movies AS (
    SELECT 
        m.movie_id,
        AVG(CAST(pi.info AS numeric)) AS avg_rating
    FROM complete_cast m
    JOIN person_info pi ON m.subject_id = pi.person_id
    WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY m.movie_id
    HAVING AVG(CAST(pi.info AS numeric)) > 7
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.production_companies,
    hr.avg_rating
FROM movie_details md
LEFT JOIN high_rated_movies hr ON md.movie_id = hr.movie_id
WHERE md.production_year >= 2000 
  AND (md.production_companies IS NULL OR md.production_companies >= 2)
ORDER BY hr.avg_rating DESC NULLS LAST, md.production_year ASC;
