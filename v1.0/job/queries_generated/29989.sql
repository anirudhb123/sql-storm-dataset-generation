WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT CONCAT(an.name, ' (', rt.role, ')') SEPARATOR ', ') AS cast_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword kw ON mk.keyword_id = kw.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    companies,
    keywords,
    cast_info,
    CHAR_LENGTH(movie_title) AS title_length,
    UPPER(movie_title) AS title_uppercase,
    (SELECT COUNT(*) FROM complete_cast WHERE movie_id = movie_details.movie_id) AS total_cast
FROM movie_details
ORDER BY production_year DESC, title_length DESC;
