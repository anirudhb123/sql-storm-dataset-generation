WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.company_type_id IS NOT NULL) OVER (PARTITION BY t.movie_id) AS company_count,
        AVG(CASE WHEN ka.surname_pcode IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.movie_id) AS avg_surname_pcode_not_null
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        title AS ti ON t.id = ti.id
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ka ON ka.person_id = c.person_id
    WHERE 
        t.production_year > 2000
        AND ka.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS m
    JOIN 
        keyword AS k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieRatings AS (
    SELECT 
        movie_id,
        COUNT(*) FILTER (WHERE rating >= 4) AS high_ratings,
        COUNT(*) FILTER (WHERE rating < 4) AS low_ratings
    FROM 
        (
            SELECT 
                movie_id,
                CASE 
                    WHEN info LIKE '%excellent%' THEN 5
                    WHEN info LIKE '%good%' THEN 4
                    WHEN info LIKE '%average%' THEN 3
                    WHEN info LIKE '%poor%' THEN 2
                    WHEN info LIKE '%terrible%' THEN 1
                    ELSE NULL 
                END AS rating
            FROM 
                movie_info
        ) AS rated_movies
    GROUP BY 
        movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.title_rank,
    mk.keywords,
    COALESCE(mr.high_ratings, 0) AS high_ratings,
    COALESCE(mr.low_ratings, 0) AS low_ratings,
    CASE 
        WHEN r.avg_surname_pcode_not_null IS NULL THEN 'No surname pcode'
        WHEN r.avg_surname_pcode_not_null = 0 THEN 'All null'
        ELSE 'Has some'
    END AS surname_pcode_status,
    CASE 
        WHEN r.company_count > 5 THEN 'Major Production'
        ELSE 'Indie Production'
    END AS production_type
FROM 
    RankedMovies AS r
LEFT JOIN 
    MovieKeywords AS mk ON r.id = mk.movie_id
LEFT JOIN 
    MovieRatings AS mr ON r.id = mr.movie_id
WHERE 
    r.title_rank <= 10
ORDER BY 
    r.production_year DESC,
    r.title_rank;
