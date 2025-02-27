WITH movie_count AS (
    SELECT 
        co.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies_produced
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        co.name
),
top_companies AS (
    SELECT 
        company_name,
        total_movies_produced,
        ROW_NUMBER() OVER (ORDER BY total_movies_produced DESC) AS rank
    FROM 
        movie_count
    WHERE 
        total_movies_produced > 0
),
popular_titles AS (
    SELECT 
        t.title,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title
    ORDER BY 
        cast_count DESC
    LIMIT 5
)
SELECT 
    tc.company_name,
    tc.total_movies_produced,
    pt.title AS popular_title,
    pt.cast_count
FROM 
    top_companies tc
JOIN 
    (SELECT title, cast_count FROM popular_titles) pt ON tc.rank = pt.cast_count
ORDER BY 
    tc.rank;

This SQL query pulls together various aspects of the database to benchmark string processing involving company names and movie titles. It calculates the total number of movies produced by each company, identifies the top producing companies, and extracts the most popular movie titles based on the number of unique cast members. The results join these tables, giving insights into popular titles associated with top companies.
