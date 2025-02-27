WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(c.id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) as rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
keyword_summary AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.num_cast_members,
    ks.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_summary ks ON rm.rank = 1 AND rm.title = ks.movie_id 
WHERE 
    rm.num_cast_members > 5
ORDER BY 
    rm.production_year DESC,
    rm.num_cast_members DESC;
