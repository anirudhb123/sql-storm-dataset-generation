WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(CASE WHEN mc.company_type_id = 1 THEN 1 ELSE 0 END), 0) AS has_production_company,
        COALESCE(SUM(CASE WHEN mc.company_type_id = 2 THEN 1 ELSE 0 END), 0) AS has_distribution_company
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
GenreCount AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    GROUP BY 
        mt.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.has_production_company,
    mh.has_distribution_company,
    gc.genre_count,
    cd.actor_count,
    cd.actors
FROM 
    MovieHierarchy mh
LEFT JOIN 
    GenreCount gc ON mh.movie_id = gc.movie_id
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
WHERE 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC,
    gc.genre_count DESC,
    cd.actor_count DESC;
