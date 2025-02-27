WITH MovieRatings AS (
    SELECT 
        movie_id,
        AVG(CASE WHEN rating IS NOT NULL THEN rating ELSE 0 END) AS avg_rating,
        COUNT(rating) AS rating_count
    FROM (
        SELECT 
            movie_id,
            
            (CASE 
                WHEN m.production_year < 2000 THEN NULL 
                WHEN m.production_year BETWEEN 2000 AND 2010 THEN 7 + RANDOM() * 3  
                ELSE 5 + RANDOM() * 5 
            END) AS rating
        FROM aka_title m
        WHERE m.production_year IS NOT NULL
    ) AS ratings
    GROUP BY movie_id
), QualifiedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(r.avg_rating, 0) AS average_rating,
        r.rating_count
    FROM aka_title t
    LEFT JOIN MovieRatings r ON t.id = r.movie_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%') 
    AND (r.rating_count > 0 OR t.production_year >= 2015)  
),
DetailedMovieInfo AS (
    SELECT 
        qm.title,
        qm.production_year,
        qm.average_rating,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM QualifiedMovies qm
    LEFT JOIN movie_companies mc ON mc.movie_id = (
        SELECT id FROM aka_title WHERE title = qm.title LIMIT 1
    )
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = (
        SELECT id FROM aka_title WHERE title = qm.title LIMIT 1
    )
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY qm.title, qm.production_year, qm.average_rating
)
SELECT 
    d.title,
    d.production_year,
    d.average_rating,
    d.company_names,
    d.keywords
FROM DetailedMovieInfo d
WHERE (d.average_rating > 8 AND d.production_year < 2020)
   OR (d.average_rating BETWEEN 5 AND 8 AND d.company_names IS NOT NULL)
ORDER BY d.production_year DESC, d.average_rating DESC
LIMIT 10;