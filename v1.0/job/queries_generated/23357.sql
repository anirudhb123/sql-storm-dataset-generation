WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS total_cast,
        AVG(mi.info) OVER (PARTITION BY t.id ORDER BY t.production_year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS average_movie_info
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%summary%')
    WHERE 
        t.kind_id IS NOT NULL 
        AND (t.production_year >= 2000 OR t.title IS NULL)
),
CombinedInfo AS (
    SELECT 
        nm.name AS actor_name,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.average_movie_info,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.total_cast DESC) AS rn
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name nm ON ci.person_id = nm.person_id
)
SELECT 
    actor_name, 
    title, 
    production_year, 
    total_cast, 
    average_movie_info
FROM 
    CombinedInfo
WHERE 
    rn <= 5
ORDER BY 
    production_year DESC, 
    total_cast DESC;

-- Union clause for adding obscure titles with a specific keyword requirement 
UNION 

SELECT 
    DISTINCT cn.name AS actor_name,
    at.title, 
    at.production_year, 
    COUNT(mk.id) AS total_keywords,
    NULL AS average_movie_info
FROM 
    aka_title at 
INNER JOIN 
    movie_keyword mk ON at.id = mk.movie_id 
INNER JOIN 
    cast_info ci ON at.id = ci.movie_id 
INNER JOIN 
    aka_name cn ON ci.person_id = cn.person_id 
WHERE 
    mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%horror%') 
GROUP BY 
    cn.name, at.title, at.production_year 
HAVING 
    COUNT(mk.id) > 2 
ORDER BY 
    at.production_year ASC;
