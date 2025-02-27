
WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM aka_name AS a
    JOIN cast_info AS c ON a.person_id = c.person_id
    JOIN aka_title AS t ON c.movie_id = t.movie_id
    WHERE a.name ILIKE '%Smith%'  
      AND t.production_year >= 2000  
),

company_with_keywords AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        k.keyword AS movie_keyword
    FROM movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    JOIN movie_keyword AS mk ON mc.movie_id = mk.movie_id
    JOIN keyword AS k ON mk.keyword_id = k.id
    WHERE c.country_code = 'USA'
)

SELECT 
    r.aka_name,
    r.movie_title,
    r.production_year,
    c.company_name,
    STRING_AGG(DISTINCT c.movie_keyword, ', ') AS keywords  
FROM ranked_titles AS r
JOIN company_with_keywords AS c ON r.aka_id = c.movie_id  
WHERE r.rank <= 3  
GROUP BY r.aka_name, r.movie_title, r.production_year, c.company_name
ORDER BY r.production_year DESC, r.aka_name;
