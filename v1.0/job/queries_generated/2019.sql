WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        COALESCE(mi.info, 'No Info') AS additional_info
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        movie_info mi ON tm.production_year = (SELECT production_year FROM aka_title WHERE id = mi.movie_id)
),
final_summary AS (
    SELECT 
        md.title,
        md.production_year,
        md.movie_keyword,
        md.additional_info,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_details md
    LEFT JOIN 
        movie_companies mc ON md.title = (SELECT title FROM aka_title WHERE movie_id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        md.title, md.production_year, md.movie_keyword, md.additional_info, cn.name
)
SELECT 
    fs.title,
    fs.production_year,
    fs.movie_keyword,
    fs.additional_info,
    fs.company_name,
    fs.company_count
FROM 
    final_summary fs
WHERE 
    fs.company_count > 1
ORDER BY 
    fs.production_year DESC, 
    fs.company_count DESC
FETCH FIRST 10 ROWS ONLY;
