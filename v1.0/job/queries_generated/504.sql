WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name ASC) AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
ranked_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actors,
        cd.companies,
        md.keyword_count,
        RANK() OVER (ORDER BY md.keyword_count DESC, md.production_year ASC) AS rank
    FROM movie_details md
    LEFT JOIN company_details cd ON md.title = cd.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.actors,
    r.companies,
    r.keyword_count,
    CASE 
        WHEN r.rank <= 10 THEN 'Top 10'
        ELSE 'Outside Top 10'
    END AS ranking_category
FROM ranked_movies r
WHERE r.title IS NOT NULL
ORDER BY r.rank;
