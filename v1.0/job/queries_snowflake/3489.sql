
WITH movie_details AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name n ON c.person_id = n.person_id
    GROUP BY a.id, a.title, a.production_year
),
keyword_info AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies,
        COUNT(DISTINCT co.id) AS company_count
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
ranked_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        ki.keywords,
        ci.companies,
        ci.company_count,
        RANK() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rank
    FROM movie_details md
    LEFT JOIN keyword_info ki ON md.id = ki.movie_id
    LEFT JOIN company_info ci ON md.id = ci.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    COALESCE(keywords, 'No keywords') AS keywords,
    COALESCE(companies, 'No companies') AS companies,
    rank
FROM ranked_movies
WHERE rank <= 10
ORDER BY cast_count DESC;
