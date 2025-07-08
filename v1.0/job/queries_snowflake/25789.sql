
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(aka.name, ', ') WITHIN GROUP (ORDER BY aka.name) AS actors,
        LISTAGG(kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS companies_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name aka ON ci.person_id = aka.person_id
    LEFT JOIN
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN
        keyword kw ON mw.keyword_id = kw.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY
        t.id, t.title, t.production_year
),
info_summary AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        CASE 
            WHEN md.companies_count > 3 THEN 'High Production'
            WHEN md.companies_count BETWEEN 1 AND 3 THEN 'Medium Production'
            ELSE 'Low Production' 
        END AS production_scale,
        md.actors,
        md.keywords,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS ranking
    FROM 
        movie_details md
)
SELECT 
    isum.movie_id,
    isum.title,
    isum.production_year,
    isum.production_scale,
    isum.actors,
    isum.keywords
FROM 
    info_summary isum
WHERE 
    isum.ranking <= 10
ORDER BY
    isum.production_year DESC;
