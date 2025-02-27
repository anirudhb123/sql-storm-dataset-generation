WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast
    FROM 
        cast_info c
    INNER JOIN 
        ranked_movies rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.num_cast,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    md.title,
    md.production_year,
    md.num_cast,
    md.keyword,
    md.company_name,
    CASE 
        WHEN md.production_year >= 2000 THEN 'Modern Era'
        WHEN md.production_year >= 1980 THEN 'Classic Era'
        ELSE 'Golden Age'
    END AS era,
    COUNT(DISTINCT ci.note) OVER (PARTITION BY md.movie_id) AS unique_notes_count,
    STRING_AGG(DISTINCT ci.note, '; ') WITHIN GROUP (ORDER BY ci.note) AS all_notes
FROM 
    movie_details md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
WHERE 
    (md.num_cast > 2 AND md.production_year IS NOT NULL)
    OR (md.keyword = 'Action' AND md.company_name IS NOT NULL)
ORDER BY 
    md.production_year DESC,
    md.num_cast DESC
LIMIT 100;
