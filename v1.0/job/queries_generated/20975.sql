WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ca ON t.id = ca.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
ActorStatistics AS (
    SELECT 
        actor_name,
        COUNT(title_id) AS movie_count,
        AVG(production_year) AS avg_production_year,
        STRING_AGG(title, ', ') AS movies_list
    FROM 
        RankedMovies
    WHERE 
        actor_rank = 1
    GROUP BY 
        actor_name
),
KeywordSearch AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    a.actor_name,
    a.movie_count,
    a.avg_production_year,
    k.keyword_list
FROM 
    ActorStatistics a
LEFT JOIN 
    KeywordSearch k ON a.movie_count > 5 -- Filter actors with more than 5 movies
WHERE 
    a.avg_production_year > (
        SELECT 
            AVG(production_year) 
        FROM 
            RankedMovies
    )
ORDER BY 
    a.movie_count DESC, 
    a.avg_production_year ASC;

-- Additional complexity with NULL handling
SELECT 
    t.title,
    COALESCE(cn.name, 'No Company') AS company_name,
    tc.kind AS company_type,
    COUNT(m.id) AS total_movies
FROM 
    movie_companies mc
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type tc ON mc.company_type_id = tc.id
LEFT JOIN 
    aka_title t ON mc.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info IS NULL OR mi.info != 'Confirmed'
GROUP BY 
    t.title, cn.name, tc.kind
HAVING 
    COUNT(m.id) > 1 AND 
    cn.country_code IN ('USA', 'UK')
ORDER BY 
    total_movies DESC, 
    t.title;

