WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_titles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
),
cast_details AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    cd.actors,
    cd.roles,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    top_titles tt
LEFT JOIN 
    complete_cast cc ON tt.title_id = cc.movie_id
LEFT JOIN 
    cast_details cd ON tt.title_id = cd.movie_id
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
ORDER BY 
    tt.production_year DESC, tt.title;
