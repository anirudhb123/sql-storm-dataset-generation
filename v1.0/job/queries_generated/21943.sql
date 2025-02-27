WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast,
        COALESCE(SUM(mi.info) FILTER (WHERE it.info = 'budget'), 0) AS total_budget
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        movie_id, title, production_year, cast_count, total_budget
    FROM 
        ranked_movies
    WHERE 
        cast_count > 3 
        AND total_budget > 0
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
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN fm.rank_by_cast <= 5 THEN 'Top Cast'
        WHEN fm.rank_by_cast <= 10 THEN 'Moderate Cast'
        ELSE 'Minor Cast'
    END AS cast_ranking
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_keywords mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    aka_name an ON an.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = fm.movie_id)
WHERE 
    an.name IS NOT NULL
    AND (fm.cast_count + COALESCE(NULLIF(fm.total_budget, 0), 1)) > 10
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
