WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),
RoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IN (SELECT id FROM role_type WHERE role = 'Actor') THEN 1 ELSE 0 END) AS actor_count,
        SUM(CASE WHEN ci.role_id IN (SELECT id FROM role_type WHERE role = 'Director') THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FeaturedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        rc.total_cast,
        rc.actor_count,
        rc.director_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY rc.total_cast DESC) AS rank
    FROM 
        MovieHierarchy mh
    JOIN 
        RoleCounts rc ON mh.movie_id = rc.movie_id
    WHERE 
        mh.level < 3  -- Limit to top-level movies and 1 level of hierarchy
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    ARRAY_AGG(DISTINCT ak.name) AS cast_names,
    CONCAT('Total Cast: ', fm.total_cast, ', Actors: ', fm.actor_count, ', Directors: ', COALESCE(fm.director_count, 0)) AS detailed_info
FROM 
    FeaturedMovies fm
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    fm.rank <= 5  -- Get only top 5 movies per year
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.actor_count, fm.director_count
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC;
