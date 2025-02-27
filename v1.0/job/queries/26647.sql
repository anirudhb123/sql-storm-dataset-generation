WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
popular_names AS (
    SELECT 
        a.name AS aka_name, 
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(c.movie_id) > 5
),
company_details AS (
    SELECT 
        c.id AS company_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title_id, 
    rt.title, 
    rt.production_year, 
    pn.aka_name, 
    pn.movie_count, 
    cd.company_name, 
    cd.company_type
FROM 
    ranked_titles rt
LEFT JOIN 
    popular_names pn ON rt.title_id = pn.movie_count
LEFT JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    company_details cd ON mc.company_id = cd.company_id
WHERE 
    rt.rank = 1 AND 
    rt.production_year > 2000
ORDER BY 
    rt.production_year DESC, 
    pn.movie_count DESC
LIMIT 50;