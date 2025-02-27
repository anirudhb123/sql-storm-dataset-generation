WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL 
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
DirectorInfo AS (
    SELECT 
        person_id,
        name,
        COUNT(m.movie_id) AS directed_movies
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    WHERE 
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        person_id, name
),
Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        di.directed_movies,
        k.all_keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        DirectorInfo di ON mh.movie_id = (SELECT movie_id FROM cast_info ci WHERE ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director') AND ci.movie_id = mh.movie_id LIMIT 1)
    LEFT JOIN 
        Keywords k ON mh.movie_id = k.movie_id
    WHERE 
        mh.level = 0
    AND 
        di.directed_movies > 5 
) 
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.all_keywords, 'No Keywords') AS keywords,
    fm.directed_movies
FROM 
    FilteredMovies fm
WHERE 
    fm.rn <= 10
ORDER BY 
    fm.production_year DESC, fm.title;
