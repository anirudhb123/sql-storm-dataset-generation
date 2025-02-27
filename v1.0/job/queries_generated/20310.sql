WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year, t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_stats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN ti.production_year IS NOT NULL THEN ti.production_year ELSE 0 END) AS avg_production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title ti ON ti.id = c.movie_id
    GROUP BY 
        a.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
company_movie_info AS (
    SELECT 
        m.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        mti.info AS movie_info
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    JOIN 
        title m ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mti ON mti.movie_id = m.id AND mti.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    a.name,
    t.title,
    COALESCE(r.year_rank, 0) AS year_rank,
    COALESCE(ams.movie_count, 0) AS total_movies,
    COALESCE(ams.avg_production_year, NULL) AS average_year,
    mk.keywords,
    cm.company_name,
    cm.company_type,
    cm.movie_info
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    ranked_titles r ON r.title_id = ci.movie_id
LEFT JOIN 
    actor_movie_stats ams ON ams.person_id = a.person_id
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    company_movie_info cm ON cm.movie_id = ci.movie_id
WHERE 
    (ams.movie_count > 0 OR mk.keywords IS NOT NULL)
    AND (cm.company_type IS NOT NULL OR cm.movie_info IS NULL)
ORDER BY 
    total_movies DESC, average_year ASC;
