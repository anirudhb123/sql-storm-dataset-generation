WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        ma.title, 
        ma.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS ma ON ma.id = ml.linked_movie_id
),
MovieCastStats AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info AS c
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(mk.keyword_id) > 3
),
MaxProducer AS (
    SELECT 
        mc.movie_id,
        cn.name AS producer_name 
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON cn.id = mc.company_id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'producer')
),
FinalMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mcs.total_cast,
        COALESCE(mcs.cast_names, 'No Cast') AS cast_names,
        pv.producer_name,
        pk.keyword_count
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        MovieCastStats AS mcs ON mh.movie_id = mcs.movie_id
    LEFT JOIN 
        MaxProducer AS pv ON mh.movie_id = pv.movie_id
    LEFT JOIN 
        PopularKeywords AS pk ON mh.movie_id = pk.movie_id
)
SELECT 
    *,
    CASE 
        WHEN keyword_count IS NOT NULL AND total_cast > 5 THEN 'High Engagement'
        WHEN keyword_count IS NULL AND total_cast <= 5 THEN 'Niche' 
        ELSE 'Moderate' 
    END AS engagement_level
FROM 
    FinalMovies
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    total_cast DESC;
