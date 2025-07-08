
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, ', ') AS info_list
    FROM 
        movie_info mi
    INNER JOIN 
        movie_details md ON md.movie_id = mi.movie_id
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        mi.info_list,
        ROW_NUMBER() OVER (ORDER BY md.total_cast DESC) AS rank
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info_summary mi ON md.movie_id = mi.movie_id
    WHERE 
        md.total_cast > 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.info_list, 'No info available') AS info_summary,
    tm.total_cast,
    CASE 
        WHEN tm.rank <= 10 THEN 'Top 10'
        ELSE 'Below Top 10'
    END AS ranking_category
FROM 
    top_movies tm
ORDER BY 
    tm.rank;
