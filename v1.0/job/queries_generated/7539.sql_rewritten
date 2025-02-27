WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
filtered_movies AS (
    SELECT 
        a.name AS actor_name,
        ct.kind AS cast_type,
        ak.title,
        ak.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title ak ON ci.movie_id = ak.movie_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        a.name LIKE 'A%' 
)
SELECT 
    f.actor_name, 
    f.cast_type, 
    f.title, 
    f.production_year 
FROM 
    filtered_movies f
JOIN 
    ranked_titles r ON f.production_year = r.production_year 
WHERE 
    r.rank <= 10
ORDER BY 
    f.production_year DESC, f.actor_name;