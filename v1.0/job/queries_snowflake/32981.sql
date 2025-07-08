
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(ci.person_id) > 0
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.actor_count
    FROM 
        TopMovies tm
    WHERE 
        tm.rank <= 5
)
SELECT 
    fm.title AS Movie_Title,
    fm.production_year AS Year,
    fm.actor_count AS Actor_Count,
    COALESCE(cn.name, 'Unknown') AS Company_Name,
    COALESCE (
        (SELECT LISTAGG(ki.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword ki ON mk.keyword_id = ki.id 
         WHERE mk.movie_id = fm.movie_id), 
        'No keywords') AS Keywords,
    (SELECT COUNT(DISTINCT ci2.person_id) 
        FROM cast_info ci2 
        WHERE ci2.movie_id = fm.movie_id) AS Unique_Cast
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
ORDER BY 
    fm.production_year, 
    fm.actor_count DESC;
