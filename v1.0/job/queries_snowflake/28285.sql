
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword kc ON kc.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year,
        rt.keyword_count 
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),

MovieDetails AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        tm.keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.title_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.title_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year, tm.keyword_count
)

SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.cast_count AS Cast_Count,
    md.keyword_count AS Keyword_Count,
    md.company_names AS Company_Names
FROM 
    MovieDetails md
JOIN 
    RankedTitles rt ON md.title_id = rt.title_id
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
