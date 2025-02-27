WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id
), HighActorCountMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.actor_count,
        RANK() OVER (ORDER BY rm.actor_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > 10
)
SELECT 
    ham.title,
    ham.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name), 'No aliases') AS alias_names,
    COALESCE(GROUP_CONCAT(DISTINCT cn.name), 'No companies') AS company_names,
    ham.actor_count
FROM 
    HighActorCountMovies ham
LEFT JOIN 
    movie_companies mc ON ham.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    aka_title at ON ham.movie_id = at.movie_id
LEFT JOIN 
    aka_name ak ON at.id = ak.id
WHERE 
    ham.rank <= 10
GROUP BY 
    ham.movie_id, ham.title, ham.production_year, ham.actor_count
ORDER BY 
    ham.actor_count DESC;
