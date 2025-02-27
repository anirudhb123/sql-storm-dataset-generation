WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.season_nr,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Top level movies

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.season_nr,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.id  -- Creating the hierarchy
),
TopMovies AS (
    SELECT
        mh.id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.id = ci.movie_id
    GROUP BY 
        mh.id, mh.title, mh.production_year
),
DirectorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        rt.role = 'Director'
    GROUP BY 
        c.movie_id
),
PopularMovies AS (
    SELECT 
        tm.id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        dm.director_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        DirectorMovies dm ON tm.id = dm.movie_id
    WHERE 
        tm.movie_rank <= 5  -- Top 5 movies per year
)
SELECT 
    pm.title,
    pm.production_year,
    COALESCE(pm.cast_count, 0) AS total_cast,
    COALESCE(pm.director_count, 0) AS total_directors,
    COALESCE(cd.name, 'Unknown') AS central_director
FROM 
    PopularMovies pm
LEFT JOIN 
    cast_info ci ON pm.id = ci.movie_id
LEFT JOIN 
    aka_name na ON ci.person_id = na.person_id AND na.name_pcode_nf IS NOT NULL
LEFT JOIN 
    (SELECT 
         c.movie_id,
         na.name
     FROM 
         cast_info c
     JOIN 
         aka_name na ON c.person_id = na.person_id
     WHERE 
         c.role_id = (SELECT id FROM role_type WHERE role = 'Director')
         AND na.name IS NOT NULL
     ) cd ON pm.id = cd.movie_id
WHERE 
    pm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    pm.production_year DESC, pm.title;
