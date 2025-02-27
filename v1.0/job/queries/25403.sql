
WITH movie_summary AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
average_cast_size AS (
    SELECT 
        AVG(cast_count) AS avg_cast_size
    FROM 
        movie_summary
),
keyword_count AS (
    SELECT 
        COUNT(DISTINCT keyword) AS total_keywords
    FROM 
        keyword
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.aka_names,
    ms.cast_count,
    ms.keywords,
    ms.companies,
    avg.avg_cast_size,
    kc.total_keywords
FROM 
    movie_summary ms,
    average_cast_size avg,
    keyword_count kc
ORDER BY 
    ms.production_year DESC;
