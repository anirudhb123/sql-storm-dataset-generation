
WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        at.id, at.title, at.production_year
), 

top_ranked_titles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count
    FROM 
        ranked_titles rt
    WHERE 
        rt.rank <= 5
), 

detailed_info AS (
    SELECT 
        tr.title_id,
        tr.title,
        tr.production_year,
        tr.cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        top_ranked_titles tr
    LEFT JOIN 
        complete_cast cc ON tr.title_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tr.title_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        tr.title_id, tr.title, tr.production_year, tr.cast_count
)

SELECT 
    d.title,
    d.production_year,
    d.cast_count,
    d.actors,
    d.companies
FROM 
    detailed_info d
ORDER BY 
    d.production_year DESC, d.cast_count DESC;
