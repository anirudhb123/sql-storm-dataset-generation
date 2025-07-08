
WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn,
        kt.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_summary AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.cast_names, 'N/A') AS cast_members,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        cast_details cd ON t.id = cd.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year, cd.total_cast, cd.cast_names
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.cast_members,
    ms.keyword_count,
    CASE 
        WHEN ms.total_cast > 10 THEN 'Large Cast'
        WHEN ms.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = ms.production_year) AS same_year_count,
    (SELECT LISTAGG(DISTINCT rt.keyword, ', ') WITHIN GROUP (ORDER BY rt.keyword) 
     FROM ranked_titles rt 
     WHERE rt.production_year = ms.production_year 
     AND rt.rn <= 5) AS top_keywords
FROM 
    movie_summary ms
WHERE 
    ms.keyword_count > 0
ORDER BY 
    ms.production_year DESC, 
    ms.keyword_count DESC;
