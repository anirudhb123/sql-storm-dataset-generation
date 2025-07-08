
WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year
    FROM title t
    LEFT JOIN cast_info c ON c.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM ranked_movies rm
    WHERE rm.rank_per_year = 1
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_titles AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ct.companies, 'No Companies') AS companies
FROM filtered_movies fm
LEFT JOIN movie_keywords mk ON fm.title_id = mk.movie_id
LEFT JOIN company_titles ct ON fm.title_id = ct.movie_id
WHERE fm.production_year > 2000
    AND (SELECT COUNT(*) FROM aka_title at WHERE at.title = fm.title AND at.production_year = fm.production_year) > 1
ORDER BY fm.production_year DESC, fm.cast_count DESC;
