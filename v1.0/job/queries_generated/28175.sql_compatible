
WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
        AND ak.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    LENGTH(md.aka_names) AS aka_name_length,
    LENGTH(md.keywords) AS keyword_length,
    LENGTH(md.company_names) AS company_count_length
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, aka_name_length DESC;
