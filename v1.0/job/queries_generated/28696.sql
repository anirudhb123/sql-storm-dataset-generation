WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS summary,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS box_office,
        r.role AS main_role,
        k.keyword AS movie_keyword
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_title ak ON m.id = ak.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, r.role, k.keyword
),
ranked_movies_with_cast AS (
    SELECT 
        movie_id,
        movie_title,
        cast_count,
        aka_names,
        summary,
        box_office,
        main_role,
        movie_keyword,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    rm.movie_title,
    rm.cast_count,
    rm.aka_names,
    rm.summary,
    rm.box_office,
    rm.main_role,
    rm.movie_keyword,
    rm.rank
FROM 
    ranked_movies_with_cast rm
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.rank, rm.movie_title;

This SQL query aims at benchmarking string processing within the context of a movie database. It combines several tables to extract meaningful insights about movies, including alternative names, summaries, and their cast counts. The use of Common Table Expressions (CTEs) and aggregation functions optimizes the performance of string processing operations and gives a clear structure to the query.
