WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'related')
), 
ActorAge AS (
    SELECT 
        ka.person_id,
        AVG(DATE_PART('year', AGE(pi.info::date))) AS average_age
    FROM 
        aka_name ka
    JOIN 
        person_info pi ON ka.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
    GROUP BY 
        ka.person_id
), 
ActorRole AS (
    SELECT 
        ci.person_id,
        rt.role AS role_type,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
), 
RankedActors AS (
    SELECT 
        aa.id AS actor_id,
        an.name,
        ar.role_type,
        ar.role_count,
        aa.average_age,
        RANK() OVER (PARTITION BY ar.role_type ORDER BY ar.role_count DESC) AS rank
    FROM 
        aka_name an
    JOIN 
        ActorAge aa ON an.person_id = aa.person_id
    JOIN 
        ActorRole ar ON an.person_id = ar.person_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ra.name AS actor_name,
    ra.role_type,
    ra.average_age,
    ra.rank
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    RankedActors ra ON ci.person_id = ra.actor_id
WHERE 
    (mh.production_year > 2000 AND ra.average_age IS NOT NULL)
    OR (mh.production_year <= 2000 AND ra.role_count > (SELECT COUNT(*) FROM role_type))
    AND ra.rank <= 3
ORDER BY 
    mh.production_year DESC, ra.role_count DESC;
