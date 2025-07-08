
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS title_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_titles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.company_count
    FROM 
        ranked_titles rt
    WHERE 
        rt.title_rank <= 10
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    tt.company_count,
    cd.cast_member_count,
    cd.cast_names
FROM 
    top_titles tt
LEFT JOIN 
    cast_details cd ON tt.title_id = cd.movie_id
ORDER BY 
    tt.company_count DESC, 
    cd.cast_member_count DESC;
