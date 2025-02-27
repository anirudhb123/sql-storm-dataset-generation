WITH MovieRatings AS (
    SELECT 
        mt.movie_id,
        COUNT(*) AS total_reviews,
        AVG(COALESCE(r.rating, 0)) AS average_rating
    FROM 
        movie_info mi
    LEFT JOIN 
        (SELECT 
            movie_id, 
            rating 
         FROM 
            movie_info 
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        ) AS r ON mi.movie_id = r.movie_id
    GROUP BY 
        mt.movie_id
),
RecentTitles AS (
    SELECT 
        title.id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id DESC) AS rn
    FROM 
        title
    WHERE 
        title.production_year >= 2020
),
TopMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mr.total_reviews,
        mr.average_rating,
        ROW_NUMBER() OVER (ORDER BY mr.average_rating DESC NULLS LAST, mr.total_reviews DESC) AS rank
    FROM 
        RecentTitles rt
    JOIN 
        aka_title at ON rt.id = at.id
    JOIN 
        movie_info mi ON at.movie_id = mi.movie_id
    JOIN 
        MovieRatings mr ON at.movie_id = mr.movie_id
    WHERE 
        rt.rn = 1
)
SELECT 
    at.title,
    COALESCE(mc.name, 'Unknown Production Company') AS company_name,
    t.production_year,
    COALESCE(t.rank, 0) AS rank,
    COALESCE(mr.average_rating, 'No Rating') AS average_rating
FROM 
    TopMovies t
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
WHERE 
    mi.info IS NOT NULL
ORDER BY 
    t.rank, t.average_rating DESC;
