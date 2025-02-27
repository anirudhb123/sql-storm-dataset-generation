
WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        p.name AS person_name,
        r.role AS person_role,
        c.note AS character_note,
        COALESCE(mn.name, 'Unknown') AS company_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN person_info pi ON cc.subject_id = pi.person_id
    JOIN aka_name p ON pi.person_id = p.person_id 
    JOIN cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    JOIN role_type r ON c.role_id = r.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name mn ON mc.company_id = mn.id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT CONCAT(person_name, ' (', person_role, ')'), '; ') AS cast_details,
    COUNT(DISTINCT company_name) AS company_count
FROM movie_data
GROUP BY movie_id, movie_title, production_year
ORDER BY production_year DESC, movie_title;
