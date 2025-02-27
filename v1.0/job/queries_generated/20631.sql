WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
high_ranked_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_movies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
movie_info_combined AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'Rating' THEN mi.info ELSE NULL END, ', ') AS ratings,
        STRING_AGG(CASE WHEN it.info = 'Summary' THEN mi.info ELSE NULL END, ', ') AS summaries
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    mk.keywords,
    mc.company_count,
    mi.ratings,
    mi.summaries
FROM 
    high_ranked_movies hm
LEFT JOIN 
    movie_keywords mk ON hm.movie_id = mk.movie_id
LEFT JOIN 
    company_movies mc ON hm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_combined mi ON hm.movie_id = mi.movie_id
WHERE 
    hm.production_year IS NOT NULL 
    AND (mc.company_count IS NULL OR mc.company_count > 2)
ORDER BY 
    hm.production_year DESC, hm.movie_id;
