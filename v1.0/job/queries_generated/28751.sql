WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
filtered_titles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actors
    FROM 
        ranked_titles rt
    LEFT JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
),
movie_details AS (
    SELECT 
        ft.title_id,
        ft.title,
        ft.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keywords,
        COALESCE(mi.info, 'No Info') AS info
    FROM 
        filtered_titles ft
    LEFT JOIN 
        movie_keyword mk ON ft.title_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON ft.title_id = mi.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    md.info
FROM 
    movie_details md
WHERE 
    md.production_year = (
        SELECT MAX(production_year) 
        FROM movie_details
    )
ORDER BY 
    md.keywords ASC;
