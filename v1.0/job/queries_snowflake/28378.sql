
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
ranked_movie_info AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.actor_names,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        ranked_movies rm
)
SELECT 
    rmi.movie_title,
    rmi.production_year,
    k.keyword AS keyword,
    rmi.actor_names,
    kt.kind AS kind,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    ranked_movie_info rmi
LEFT JOIN 
    movie_keyword mk ON rmi.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON rmi.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    kind_type kt ON rmi.kind_id = kt.id
WHERE 
    rmi.rank <= 10
GROUP BY 
    rmi.movie_id, rmi.movie_title, rmi.production_year, rmi.kind_id, rmi.cast_count, rmi.actor_names, k.keyword, kt.kind
ORDER BY 
    rmi.cast_count DESC, rmi.movie_title;
