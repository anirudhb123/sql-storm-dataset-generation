WITH movie_summary AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT n.name) AS cast_names,
        ARRAY_AGG(DISTINCT c.kind) AS company_types,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON a.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN company_name cn ON a.id = cn.imdb_id 
    JOIN company_type c ON cn.id = c.id
    WHERE a.production_year >= 2000
      AND a.kind_id IN (SELECT id FROM kind_type WHERE kind NOT IN ('short', 'tv movie'))
    GROUP BY a.title, a.production_year, k.keyword
),
cast_details AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.movie_keyword,
        m.cast_names,
        m.cast_count,
        MAX(cn.name) AS production_company,
        MAX(cn.country_code) AS country
    FROM movie_summary m
    JOIN movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = m.movie_title LIMIT 1)
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY m.movie_title, m.production_year, m.movie_keyword, m.cast_names, m.cast_count
)
SELECT 
    cd.movie_title,
    cd.production_year,
    cd.movie_keyword,
    cd.cast_names,
    cd.cast_count,
    cd.production_company,
    cd.country
FROM cast_details cd
ORDER BY cd.production_year DESC, cd.movie_title;
