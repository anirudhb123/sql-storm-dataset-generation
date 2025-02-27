WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(m.note, 'No Note') AS movie_note,
        COALESCE(c.kind, 'Unknown') AS company_type
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%note%')
    WHERE
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, m.note, c.kind
    HAVING 
        COUNT(DISTINCT ci.person_id) > 2
),
keyword_count AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword) AS keyword_count
    FROM
        movie_keyword
    GROUP BY
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    md.movie_note,
    md.company_type,
    kc.keyword_count
FROM 
    movie_details md
JOIN 
    keyword_count kc ON md.movie_id = kc.movie_id
ORDER BY 
    md.production_year DESC, kc.keyword_count DESC;

This query aggregates and processes various string values related to movies, including titles, actor names, and keywords, and it filters only those movies produced after 2000 with more than two distinct actors. It also provides useful contextual information like notes and company types.
