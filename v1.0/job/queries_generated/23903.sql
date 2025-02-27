WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(lt.link_type, 'N/A') AS link_type,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(lt.link_type, 'N/A') AS link_type,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.linked_movie_id
    LEFT JOIN 
        aka_title mt ON ml.movie_id = mt.id
    LEFT JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year <= EXTRACT(YEAR FROM CURRENT_DATE) 

),
CastAndGenres AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        at.title AS movie_title,
        mt.kind_id,
        gt.gender AS actor_gender,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ca ON a.person_id = ca.person_id
    LEFT JOIN 
        aka_title at ON ca.movie_id = at.id
    LEFT JOIN 
        name gt ON a.person_id = gt.imdb_id
    WHERE 
        gt.gender IS NOT NULL
    GROUP BY 
        a.id, at.title, gt.gender, mt.kind_id
),
FilteredResults AS (
    SELECT 
        bg.movie_id,
        bg.link_type,
        cg.actor_id, 
        cg.actor_name,
        cg.actor_gender,
        ROW_NUMBER() OVER (PARTITION BY bg.movie_id ORDER BY cg.movie_count DESC) as actor_rank
    FROM 
        MovieHierarchy bg
    JOIN 
        CastAndGenres cg ON bg.movie_id = cg.movie_id
    WHERE 
        cg.actor_gender = 'M'
)
SELECT 
    fr.movie_id,
    mh.title AS movie_title,
    mc.production_year,
    fr.actor_name,
    fr.actor_gender,
    fr.link_type,
    fr.actor_rank
FROM 
    FilteredResults fr
LEFT JOIN 
    aka_title mh ON fr.movie_id = mh.id
LEFT JOIN 
    aka_title mc ON fr.movie_id = mc.id
WHERE 
    fr.actor_rank <= 3
ORDER BY 
    mc.production_year DESC, fr.actor_rank;
