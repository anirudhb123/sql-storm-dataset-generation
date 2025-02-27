
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title,
        mh.level + 1,
        e.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title AS e
    JOIN 
        MovieHierarchy AS mh ON e.episode_of_id = mh.movie_id
),
TitleKeywords AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        COALESCE(tk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(tk.keyword_count, 0) DESC, mh.title) AS rank
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        TitleKeywords AS tk ON mh.movie_id = tk.movie_id
    WHERE 
        mh.level = 1  
)
SELECT 
    t.title,
    t.production_year,
    t.keyword_count
FROM 
    TopMovies AS t
WHERE 
    t.rank <= 10  
ORDER BY 
    t.keyword_count DESC, 
    t.production_year DESC;
