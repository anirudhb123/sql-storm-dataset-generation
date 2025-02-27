WITH MovieStats AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count,
        AVG(mr.rating) AS average_rating
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN
        cast_info c ON c.movie_id = cc.movie_id
    LEFT JOIN
        movie_keyword kc ON kc.movie_id = t.id
    LEFT JOIN
        (SELECT 
            movie_id,
            AVG(rating) AS rating
        FROM 
            movie_info 
        WHERE 
            info_type_id = 1 -- Assuming 1 denotes ratings
        GROUP BY 
            movie_id) mr ON mr.movie_id = t.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        keyword_count,
        average_rating,
        RANK() OVER (ORDER BY average_rating DESC) AS rank
    FROM 
        MovieStats
    WHERE 
        actor_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.keyword_count,
    COALESCE(tm.average_rating, 'N/A') AS average_rating,
    CASE 
        WHEN tm.average_rating IS NULL THEN 'No Rating'
        WHEN tm.average_rating > 7 THEN 'Excellent'
        WHEN tm.average_rating BETWEEN 5 AND 7 THEN 'Average'
        ELSE 'Poor'
    END AS rating_comment
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
