WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS co_actors
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        C.value AS company_name,
        COALESCE(ARRAY_LENGTH(mk.keywords, 1), 0) AS keyword_count,
        COALESCE(ac.actor_name, 'Unknown Actor') AS main_actor,
        RANK() OVER (ORDER BY m.production_year DESC) AS year_rank 
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name C ON mc.company_id = C.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        actor_info ac ON ci.person_id = ac.actor_id
    GROUP BY 
        m.id, C.value, ac.actor_name
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.keywords,
    md.company_name,
    md.keyword_count,
    md.main_actor,
    CASE 
        WHEN md.year_rank <= 10 THEN 'Top Movies'
        WHEN md.year_rank > 10 AND md.year_rank <= 50 THEN 'Popular Movies'
        ELSE 'Lesser Known Movies'
    END AS movie_category,
    (SELECT COUNT(DISTINCT mi.info) FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.note IS NULL) AS null_info_count
FROM 
    movie_details md
WHERE 
    md.movie_title ILIKE '%Adventure%'
    AND EXISTS (SELECT 1 FROM ranked_titles rt WHERE rt.title_id = md.movie_id AND rt.rank_per_year <= 5)
ORDER BY 
    md.keyword_count DESC,
    md.production_year DESC
LIMIT 100 OFFSET 0;
