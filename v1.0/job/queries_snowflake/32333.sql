
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5  
),
ActorDetails AS (
    SELECT 
        ka.person_id,
        ka.name,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ka.name) AS actor_rank
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ad.name AS actor_name,
    ad.role AS actor_role,
    ad.actor_rank,
    mci.company_count,
    mci.company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorDetails ad ON mh.movie_id = ad.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.production_year > 2000  
    AND (mci.company_count IS NULL OR mci.company_count > 2)  
ORDER BY 
    mh.production_year DESC, 
    ad.actor_rank
LIMIT 100;
