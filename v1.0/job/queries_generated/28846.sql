WITH ranked_titles AS (
    SELECT 
        a.movie_id, 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS title_rank
    FROM aka_title a
    WHERE a.production_year IS NOT NULL 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
cast_statistics AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS total_cast, 
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY c.movie_id
),
movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        co.name AS company_name,
        cs.total_cast,
        cs.cast_names
    FROM ranked_titles t
    LEFT JOIN movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN cast_statistics cs ON t.movie_id = cs.movie_id
    WHERE cs.total_cast > 5 OR cs.total_cast IS NULL
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.total_cast,
    md.cast_names,
    ks.keywords
FROM movie_details md
LEFT JOIN keyword_summary ks ON md.movie_id = ks.movie_id
ORDER BY md.production_year DESC, md.title;
