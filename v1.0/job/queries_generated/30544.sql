WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        mt2.id AS movie_id,
        mt2.title,
        mt2.production_year,
        mh.level + 1
    FROM 
        aka_title mt2
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt1 ON ml.linked_movie_id = mt1.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = mt1.id
),
GenreStats AS (
    SELECT 
        COUNT(DISTINCT cm.company_id) AS total_companies,
        AVG(year) AS average_year
    FROM 
        movie_companies mc
    JOIN 
        aka_title at ON mc.movie_id = at.id
    LEFT JOIN 
        (
            SELECT 
                movie_id, 
                MIN(production_year) AS year
            FROM 
                aka_title
            GROUP BY 
                movie_id
        ) year_info ON year_info.movie_id = mc.movie_id
    WHERE 
        at.kind_id = 1 -- Example kind_id for a specific genre
    GROUP BY 
        at.kind_id
),
Actors AS (
    SELECT 
        ak.person_id,
        ak.name,
        avg(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
MovieActors AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        mt.id, mt.title
)
SELECT 
    mh.title,
    mh.production_year,
    ma.actors,
    gs.total_companies,
    gs.average_year,
    a.name AS actor_name,
    a.has_notes
FROM 
    MovieHierarchy mh
JOIN 
    MovieActors ma ON mh.movie_id = ma.movie_id
JOIN 
    GenreStats gs ON 1=1 -- Join on a constant for demonstration
LEFT JOIN 
    Actors a ON a.person_id IN (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = mh.movie_id
    )
WHERE 
    mh.level = 1 
    AND gs.total_companies > 1 
ORDER BY 
    mh.production_year DESC, 
    ma.actors;
