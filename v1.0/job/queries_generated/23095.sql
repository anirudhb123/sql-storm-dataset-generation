WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT ki.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        t.production_year IS NOT NULL
),
QualifiedActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_role
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5 AND 
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) >= 0.5
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ka.actor_id,
    ka.name,
    rm.title_rank,
    rm.keyword_count,
    (CASE 
        WHEN rm.production_year > 2000 THEN 'Modern'
        WHEN rm.production_year BETWEEN 1990 AND 2000 THEN '90s'
        ELSE 'Classic' 
    END) AS era,
    (COALESCE(ka.movie_count, 0) * 100.0 / NULLIF(rm.keyword_count, 0)) AS actor_to_keyword_ratio
FROM 
    RankedMovies rm
INNER JOIN 
    QualifiedActors ka ON ka.movie_count > 0
LEFT JOIN 
    complete_cast cc ON cc.movie_id = rm.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = rm.movie_id AND mi.info_type_id = 1
WHERE 
    mi.info IS NULL 
    OR (rm.title ILIKE '%' || COALESCE(mi.note, '') || '%')
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank
LIMIT 50 OFFSET 0;
