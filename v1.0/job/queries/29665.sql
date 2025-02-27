WITH filtered_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS main_keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND k.keyword ILIKE '%action%'
),
movie_cast AS (
    SELECT 
        f.movie_id,
        a.name AS actor_name,
        p.gender,
        cc.kind AS company_type_name
    FROM 
        filtered_movies f
    JOIN 
        cast_info c ON f.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        company_name cn ON cn.id = (
            SELECT 
                mc.company_id 
            FROM 
                movie_companies mc 
            WHERE 
                mc.movie_id = f.movie_id 
            LIMIT 1
        )
    JOIN 
        company_type cc ON cn.id = cc.id
    JOIN 
        name p ON a.person_id = p.imdb_id
)
SELECT 
    mc.movie_id,
    mf.title,
    mf.production_year,
    mc.actor_name,
    mc.gender,
    COUNT(mc.company_type_name) AS company_count
FROM 
    movie_cast mc
JOIN 
    filtered_movies mf ON mc.movie_id = mf.movie_id
GROUP BY 
    mc.movie_id, mf.title, mf.production_year, mc.actor_name, mc.gender
ORDER BY 
    mf.production_year DESC, COUNT(mc.company_type_name) DESC
LIMIT 10;