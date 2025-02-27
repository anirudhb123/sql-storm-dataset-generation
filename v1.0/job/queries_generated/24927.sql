WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast_members,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
     FROM aka_name ak 
     WHERE ak.person_id IN (SELECT c.person_id 
                            FROM cast_info c 
                            WHERE c.movie_id = tm.movie_id)
     AND ak.name IS NOT NULL) AS cast_names,
    (SELECT COUNT(DISTINCT kw.keyword)
     FROM movie_keyword mk
     JOIN keyword kw ON mk.keyword_id = kw.id
     WHERE mk.movie_id = tm.movie_id) AS unique_keywords,
    COALESCE(SUM(CASE WHEN mc.company_type_id IS NULL THEN 1 ELSE 0 END), 0) AS null_company_types,
    COALESCE(MAX(m.production_year) FILTER (WHERE m.info IS NULL), 0) AS last_year_null_info,
    ROW_NUMBER() OVER (ORDER BY tm.production_year DESC) AS row_num
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info m ON tm.movie_id = m.movie_id 
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    tm.production_year DESC, 
    tm.title;
