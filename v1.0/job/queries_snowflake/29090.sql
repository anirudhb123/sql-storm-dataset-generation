WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
top_titles AS (
    SELECT 
        title_id,
        title,
        production_year,
        kind_id,
        cast_count
    FROM 
        ranked_titles
    WHERE 
        cast_count > 5
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    tt.title,
    tt.production_year,
    kt.kind AS kind,
    array_agg(DISTINCT ak.name) AS actor_names,
    array_agg(DISTINCT ki.keyword) AS keywords
FROM 
    top_titles tt
LEFT JOIN 
    movie_keyword mk ON tt.title_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    cast_info ci ON tt.title_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    kind_type kt ON tt.kind_id = kt.id
GROUP BY 
    tt.title_id, tt.title, tt.production_year, kt.kind
ORDER BY 
    tt.production_year DESC;
