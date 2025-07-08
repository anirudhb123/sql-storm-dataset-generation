
WITH RECURSIVE actor_movies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rn,
        c.movie_id
    FROM 
        cast_info c
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        c.nr_order = 1
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.country_code) AS country_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
ranks AS (
    SELECT 
        am.person_id,
        am.title,
        am.production_year,
        ck.country_count,
        ROW_NUMBER() OVER (PARTITION BY am.person_id ORDER BY am.production_year DESC) AS movie_rank,
        am.movie_id
    FROM 
        actor_movies am
    LEFT JOIN 
        company_movies ck ON am.movie_id = ck.movie_id
)

SELECT 
    r.person_id,
    n.name,
    r.title,
    r.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    r.movie_rank
FROM 
    ranks r
JOIN 
    aka_name n ON r.person_id = n.person_id
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.movie_rank <= 5
ORDER BY 
    r.person_id, r.production_year DESC;
