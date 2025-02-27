
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(COALESCE(mi.info, '0')::numeric) AS average_info_length
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.title, t.production_year
),
KeyMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
        AND rm.actor_count > (
            SELECT AVG(actor_count) 
            FROM RankedMovies
        )
)
SELECT 
    km.title,
    km.production_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    COUNT(DISTINCT ci.role_id) FILTER (WHERE ci.note IS NOT NULL) AS noted_roles
FROM 
    KeyMovies km
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = km.title LIMIT 1)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = km.title LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = km.title LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
GROUP BY 
    km.title, km.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 
    AND COUNT(DISTINCT k.keyword) > 1
ORDER BY 
    km.production_year DESC, km.title;
