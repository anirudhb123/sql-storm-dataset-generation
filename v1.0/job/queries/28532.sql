WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
popular_movies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        cast_count, 
        aka_names
    FROM 
        ranked_movies
    WHERE 
        rank <= 10
)
SELECT 
    pm.movie_id,
    pm.movie_title,
    pm.production_year,
    pm.cast_count,
    pm.aka_names,
    mii.info AS movie_info,
    m.name AS company_name,
    ct.kind AS company_type
FROM 
    popular_movies pm
LEFT JOIN 
    movie_info mi ON pm.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx mii ON mi.id = mii.id
LEFT JOIN 
    movie_companies mc ON pm.movie_id = mc.movie_id
LEFT JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    pm.cast_count DESC, pm.production_year DESC;
