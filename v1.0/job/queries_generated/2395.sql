WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
movie_comps AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        co.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ma.actor_name,
    ma.movie_title,
    ma.production_year,
    ma.actor_order,
    COALESCE(mc.total_companies, 0) AS company_count,
    COALESCE(ks.keywords, 'No Keywords') AS keywords
FROM 
    movie_actors ma
LEFT JOIN 
    movie_comps mc ON ma.movie_title = (SELECT title FROM aka_title WHERE movie_id = ma.production_year)
LEFT JOIN 
    keyword_summary ks ON ma.production_year = ks.movie_id
WHERE 
    ma.actor_order <= 5
ORDER BY 
    ma.production_year DESC, 
    ma.actor_order;
