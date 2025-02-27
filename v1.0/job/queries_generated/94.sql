WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
), 
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_info c ON rm.production_year > 2000 AND rm.rn = 1
    GROUP BY 
        rm.title, rm.production_year
    HAVING 
        COUNT(c.person_id) > 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS cast_count,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_companies mc ON fm.title = (SELECT title FROM aka_title WHERE movie_id = mc.movie_id LIMIT 1)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    fm.title, fm.production_year, fm.cast_count
ORDER BY 
    fm.production_year DESC, fm.title;
