WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name c ON c.id = mc.company_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN aka_name a ON a.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
    GROUP BY 
        t.id, t.title, t.production_year, c.name
    HAVING 
        cast_count > 5
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.keywords,
    md.actors,
    md.cast_count
FROM movie_details md
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC
LIMIT 10;
