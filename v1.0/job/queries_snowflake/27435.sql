
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kc.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC, t.title) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
),

top_titles AS (
    SELECT 
        title_id,
        title,
        production_year,
        company_count,
        keyword_count
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
)

SELECT 
    tt.title,
    tt.production_year,
    ak.name AS actor_name,
    COUNT(ci.person_id) AS actor_count,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    top_titles tt
LEFT JOIN 
    complete_cast cc ON tt.title_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tt.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tt.title_id, tt.title, tt.production_year, ak.name
ORDER BY 
    tt.production_year DESC, tt.title;
