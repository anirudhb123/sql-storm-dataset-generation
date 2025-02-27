WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        m.movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        MovieHierarchy mh ON m.linked_movie_id = mh.movie_id
    JOIN 
        aka_title mk ON m.movie_id = mk.id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    WHERE 
        mh.level = 0
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
)
SELECT 
    t.title,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    t.production_year,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.movie_id) AS info_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS year_rank
FROM 
    TopMovies t
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    cast_info c ON t.movie_id = c.movie_id
WHERE 
    t.movie_rank <= 10
GROUP BY 
    t.movie_id, t.title, t.production_year, cn.name
ORDER BY 
    t.production_year DESC, t.title ASC;
