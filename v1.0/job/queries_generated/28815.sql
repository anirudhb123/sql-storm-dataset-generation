WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.role_id ORDER BY c.nr_order) AS role_ids,
        COUNT(DISTINCT ka.person_id) AS num_cast,
        COUNT(DISTINCT k.keyword) AS num_keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_cast,
        rm.num_keywords,
        RANK() OVER (ORDER BY rm.num_cast DESC, rm.num_keywords DESC) AS rank_order
    FROM 
        RankedMovies rm
    WHERE 
        rm.num_cast >= 5
)
SELECT 
    pm.title,
    pm.production_year,
    pm.num_cast,
    pm.num_keywords,
    rt.role AS main_role,
    STRING_AGG(DISTINCT ka.name, ', ') AS cast_names
FROM 
    PopularMovies pm
JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    aka_name ka ON ci.person_id = ka.person_id
WHERE 
    pm.rank_order <= 10
GROUP BY 
    pm.title, pm.production_year, pm.num_cast, pm.num_keywords, rt.role
ORDER BY 
    pm.num_cast DESC, pm.num_keywords DESC;
