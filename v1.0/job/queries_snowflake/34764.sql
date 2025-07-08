
WITH MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year AS movie_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        CONCAT(h.movie_title, ' -> ', m.title) AS movie_title,
        m.production_year AS movie_year,
        h.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
),
RankedCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.movie_year,
    COALESCE(rc.actor_name, 'N/A') AS main_actor,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords,
    mh.depth,
    COUNT(DISTINCT mc.company_id) AS comp_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedCast rc ON mh.movie_id = rc.movie_id AND rc.actor_rank = 1
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.movie_year, rc.actor_name, mk.keywords, mh.depth
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    mh.movie_year DESC, mh.depth ASC;
