WITH recursive movie_tree AS (
    SELECT m.id AS movie_id, 
           m.title,
           COALESCE(c1.name, 'Unknown') AS main_cast,
           COALESCE(c2.name, 'No production company') AS production_company,
           COALESCE(k.keyword, 'No keywords') AS keyword,
           ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COALESCE(c1.nr_order, 0)) AS rank
    FROM aka_title m
    LEFT JOIN cast_info ci1 ON m.id = ci1.movie_id 
    LEFT JOIN aka_name c1 ON ci1.person_id = c1.person_id AND ci1.nr_order = 1
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name c2 ON mc.company_id = c2.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id 
),
relevant_movies AS (
    SELECT movie_id, 
           title,
           main_cast,
           production_company,
           keyword
    FROM movie_tree
    WHERE rank <= 3
),
aggregate_info AS (
    SELECT 
        main_cast,
        COUNT(DISTINCT movie_id) AS movie_count,
        STRING_AGG(DISTINCT title, ', ') AS titles,
        STRING_AGG(DISTINCT production_company, ', ') AS production_companies
    FROM relevant_movies
    GROUP BY main_cast
    HAVING COUNT(DISTINCT movie_id) > 5
)

SELECT 
    ai.main_cast,
    ai.movie_count,
    ai.titles,
    ai.production_companies,
    CASE 
        WHEN ai.movie_count > 20 THEN 'Mega Star'
        WHEN ai.movie_count BETWEEN 10 AND 20 THEN 'Super Star'
        ELSE 'Star'
    END AS stardom_level,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id IN (SELECT DISTINCT movie_id FROM relevant_movies)
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS total_ratings
FROM aggregate_info ai
LEFT JOIN person_info pi ON ai.main_cast = pi.info
WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY ai.movie_count DESC 
LIMIT 10;
