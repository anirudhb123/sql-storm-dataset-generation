
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_produced
    FROM 
        aka_title t
    JOIN 
        title ti ON t.movie_id = ti.id
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
), keyword_summary AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.aliases,
    md.cast_count,
    md.companies_produced,
    COALESCE(ks.keyword_count, 0) AS keyword_count
FROM 
    movie_details md
LEFT JOIN 
    keyword_summary ks ON md.title_id = ks.movie_id
WHERE 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
