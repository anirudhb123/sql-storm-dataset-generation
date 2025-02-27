WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS cast_member,
        r.role AS role,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN role_type r ON ci.role_id = r.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id, t.title, t.production_year, c.name, r.role
),
company_movies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
    JOIN complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY m.movie_id, c.name, ct.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_member,
    md.role,
    cm.company_name,
    cm.company_type,
    md.keyword_count,
    cm.cast_count
FROM movie_details md
JOIN company_movies cm ON md.movie_title = cm.movie_title
WHERE md.production_year >= 2000
ORDER BY md.production_year DESC, md.keyword_count DESC, cm.cast_count DESC;
