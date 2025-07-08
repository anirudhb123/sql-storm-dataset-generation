
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY a.id, a.title, a.production_year
), 
filtered_movies AS (
    SELECT 
        mv.title,
        mv.production_year,
        mv.cast_names
    FROM ranked_movies mv
    WHERE mv.rank_by_cast_count <= 5
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.cast_names, 'No cast available') AS cast_names,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM filtered_movies f
LEFT JOIN movie_companies mc ON f.title = (SELECT title 
                                             FROM aka_title at 
                                             WHERE at.id IN (SELECT movie_id 
                                                             FROM complete_cast cc 
                                                             WHERE cc.subject_id = mc.movie_id))
WHERE mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
ORDER BY f.production_year DESC, f.title;
