WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
highly_rated_movies AS (
    SELECT 
        m.title_id,
        m.title,
        m.production_year,
        COALESCE(ki.keyword, 'No Keyword') AS keyword,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.cast_count DESC) AS keyword_rank
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.title_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        m.rank_by_cast <= 5
)
SELECT 
    h.title,
    h.production_year,
    h.keyword,
    COALESCE(com.name, 'Unknown Company') AS production_company,
    AVG(COALESCE(mr.info::float, 0)) AS average_rating,
    CASE 
        WHEN h.production_year IS NOT NULL THEN 'Produced in ' || h.production_year
        ELSE 'Year Unknown'
    END AS production_statement
FROM 
    highly_rated_movies h
LEFT JOIN 
    movie_companies mc ON h.title_id = mc.movie_id
LEFT JOIN 
    company_name com ON mc.company_id = com.id
LEFT JOIN 
    movie_info mi ON h.title_id = mi.movie_id 
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id 
LEFT JOIN LATERAL (
    SELECT 
        i.info 
    FROM 
        movie_info_idx i 
    WHERE 
        i.movie_id = h.title_id 
        AND i.info_type_id = it.id
        AND (i.info LIKE '%excellent%' OR i.info IS NULL)
    LIMIT 1
) AS mr ON true 
WHERE 
    h.keyword_rank <= 3 
GROUP BY 
    h.title, h.production_year, h.keyword, com.name
HAVING 
    AVG(COALESCE(mr.info::float, 0)) > 0 
ORDER BY 
    h.production_year DESC, average_rating DESC;
