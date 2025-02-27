WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        linked_movie.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link linked_movie ON h.movie_id = linked_movie.movie_id
    JOIN 
        aka_title a ON linked_movie.linked_movie_id = a.id
    WHERE 
        h.level < 5 -- Limit recursion to 5 levels
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cast_count.cast_count, 0) AS num_cast_members
    FROM 
        MovieHierarchy mh
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            COUNT(ci.person_id) AS cast_count
        FROM 
            cast_info ci
        GROUP BY 
            ci.movie_id
    ) cast_count ON mh.movie_id = cast_count.movie_id
),
RankedMovies AS (
    SELECT 
        tm.*, 
        RANK() OVER (ORDER BY tm.num_cast_members DESC, tm.production_year DESC) AS rank
    FROM 
        TopMovies tm
),
KeywordStatistics AS (
    SELECT 
        tk.movie_id,
        COUNT(tk.keyword_id) AS keyword_count
    FROM 
        movie_keyword tk
    GROUP BY 
        tk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    CAST(rm.num_cast_members AS VARCHAR) || ' cast members' AS cast_info,
    COALESCE(ks.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN rm.rank <= 10 THEN 'Top 10 Movies'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordStatistics ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.num_cast_members > 0 
ORDER BY 
    rm.rank;
