WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        COUNT(DISTINCT ci.person_id) AS total_cast, 
        AVG(mi.info_length) AS avg_info_length
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id
), 
filtered_movies AS (
    SELECT 
        movie_id, 
        title, 
        total_cast, 
        avg_info_length, 
        RANK() OVER (ORDER BY total_cast DESC, avg_info_length DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    f.title, 
    f.total_cast, 
    f.avg_info_length
FROM 
    filtered_movies f
WHERE 
    f.rank <= 10
ORDER BY 
    f.rank;
