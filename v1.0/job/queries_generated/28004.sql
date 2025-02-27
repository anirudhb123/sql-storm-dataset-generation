WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
), 
recent_titles AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year
    FROM 
        ranked_titles rt
    WHERE 
        rt.rank <= 5
)

SELECT 
    rt.title,
    rt.production_year,
    ak.name AS actor_name,
    ak.imdb_index AS actor_imdb_index,
    ci.note AS role_note,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    co.name AS company_name
FROM 
    recent_titles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    rt.production_year DESC, rt.title;
