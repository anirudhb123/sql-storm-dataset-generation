
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_with_counts AS (
    SELECT 
        m.id, 
        m.title, 
        m.production_year,
        COALESCE(mi.info, 'No Info') AS additional_info,
        COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, mi.info, mk.keywords_list
)
SELECT 
    m.title,
    m.production_year,
    m.additional_info,
    m.keywords,
    m.company_count,
    CASE 
        WHEN m.company_count IS NULL THEN 'No Companies Linked'
        WHEN m.company_count > 3 THEN 'Many Companies'
        ELSE 'Few Companies'
    END AS company_association,
    RANK() OVER (ORDER BY m.production_year DESC, m.company_count DESC) AS movie_rank
FROM 
    movie_info_with_counts m
WHERE 
    m.title IS NOT NULL AND 
    (m.additional_info IS NOT NULL OR m.keywords IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    m.company_count DESC, 
    m.title
LIMIT 10;
