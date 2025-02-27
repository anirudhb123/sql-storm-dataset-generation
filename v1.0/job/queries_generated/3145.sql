WITH MovieStats AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN cc.company_type_id IS NOT NULL THEN 1 ELSE 0 END) AS company_collaboration
    FROM aka_title a
    LEFT JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    GROUP BY a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM MovieStats
    WHERE production_year >= 2000
)
SELECT 
    t1.movie_title,
    t1.production_year,
    t1.total_cast,
    COALESCE(t2.linked_movie_count, 0) AS linked_movies,
    MAX(NULLIF(i.info, '')) AS additional_info
FROM TopMovies t1
LEFT JOIN (
    SELECT movie_id, COUNT(linked_movie_id) AS linked_movie_count
    FROM movie_link
    GROUP BY movie_id
) t2 ON t1.movie_title = (
    SELECT title 
    FROM aka_title 
    WHERE id = t2.movie_id
)
LEFT JOIN movie_info i ON i.movie_id = t1.id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
WHERE t1.rank <= 10
GROUP BY t1.movie_title, t1.production_year, t1.total_cast, t2.linked_movie_count
ORDER BY t1.total_cast DESC;
