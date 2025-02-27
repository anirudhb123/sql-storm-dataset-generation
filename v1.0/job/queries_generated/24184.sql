WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn <= 5  -- Top 5 movies per year based on cast count
),
directors AS (
    SELECT 
        ci.movie_id,
        ak.name AS director_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director') 
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_with_nulls AS (
    SELECT 
        mi.movie_id,
        COALESCE(MAX(CASE WHEN it.info = 'Budget' THEN mi.info END), 'Unknown') AS budget,
        COALESCE(MAX(CASE WHEN it.info = 'BoxOffice' THEN mi.info END), 'Not Disclosed') AS box_office,
        COALESCE(MAX(CASE WHEN it.info = 'Rating' THEN mi.info END), 'Not Rated') AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    d.director_name,
    mk.keywords,
    mn.budget,
    mn.box_office,
    mn.rating
FROM 
    top_movies tm
LEFT JOIN 
    directors d ON tm.movie_id = d.movie_id
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_with_nulls mn ON tm.movie_id = mn.movie_id
WHERE 
    (tm.production_year > 2000 OR (d.director_name IS NOT NULL AND d.director_name <> ''))
    AND (mk.keywords IS NOT NULL OR mk.keywords <> '')
ORDER BY 
    tm.production_year ASC, 
    CAST(mn.rating AS FLOAT) DESC NULLS LAST
LIMIT 100;

