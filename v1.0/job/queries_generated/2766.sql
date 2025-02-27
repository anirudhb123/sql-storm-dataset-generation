WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MoviesWithRatings AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mo.info, 'No Rating') AS rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mo ON rm.title = mo.info
    WHERE 
        mo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT 
    mwr.title,
    mwr.production_year,
    mwr.rating,
    CASE 
        WHEN mwr.rating = 'No Rating' THEN 'Unrated'
        ELSE 'Rated'
    END AS rating_status,
    (SELECT COUNT(DISTINCT c.name)
     FROM cast_info ci
     JOIN aka_name c ON ci.person_id = c.person_id
     WHERE ci.movie_id IN (SELECT movie_id FROM aka_title WHERE title = mwr.title)) AS distinct_actors
FROM 
    MoviesWithRatings mwr
WHERE 
    mwr.rank <= 5
ORDER BY 
    mwr.production_year DESC, 
    mwr.rating DESC NULLS LAST;
