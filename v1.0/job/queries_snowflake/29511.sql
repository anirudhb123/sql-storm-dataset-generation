
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS production_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.aka_names,
        md.keywords,
        md.production_companies,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS ranking
    FROM 
        movie_details md
)

SELECT 
    rm.ranking,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.keywords,
    rm.production_companies
FROM 
    ranked_movies rm
WHERE 
    rm.ranking <= 50
ORDER BY 
    rm.ranking;
