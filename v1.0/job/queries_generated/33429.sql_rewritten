WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
), 

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ki.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS featured_roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, ki.keyword
),

TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.actor_count,
        md.featured_roles,
        RANK() OVER (ORDER BY md.actor_count DESC) AS actor_rank
    FROM 
        MovieDetails md
)

SELECT 
    tm.title AS movie_title,
    tm.production_year,
    tm.keyword,
    tm.actor_count,
    tm.featured_roles,
    CASE 
        WHEN tm.featured_roles > 5 THEN 'Featured'
        WHEN tm.actor_count IS NULL THEN 'No Actors'
        ELSE 'Regular'
    END AS classification
FROM 
    TopMovies tm
WHERE 
    tm.actor_rank <= 10
ORDER BY 
    tm.actor_count DESC,
    tm.production_year DESC;