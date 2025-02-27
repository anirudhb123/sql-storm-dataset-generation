WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
top_titles AS (
    SELECT 
        title_id, title, production_year, kind, aliases, production_companies
    FROM 
        ranked_titles
    WHERE 
        rank <= 10
)
SELECT 
    tt.title,
    tt.production_year,
    tt.kind,
    tt.aliases,
    STRING_AGG(DISTINCT p.info ORDER BY p.info_type_id) AS additional_info,
    COUNT(DISTINCT c.person_id) AS cast_members
FROM 
    top_titles tt
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id
LEFT JOIN 
    person_info p ON mi.id = p.info_type_id
LEFT JOIN 
    cast_info c ON tt.title_id = c.movie_id
GROUP BY 
    tt.title, tt.production_year, tt.kind, tt.aliases
ORDER BY 
    tt.production_year DESC, tt.title;
