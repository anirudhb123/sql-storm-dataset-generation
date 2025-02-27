WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(*) OVER (PARTITION BY t.id) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
        JOIN movie_info mi ON t.id = mi.movie_id
        WHERE 
            mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Running Time') 
            AND mi.info IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rm.title, 
        rm.production_year,
        rm.actor_count,
        COALESCE(reviews.total_reviews, 0) AS total_reviews
    FROM 
        RankedMovies rm
        LEFT JOIN (
            SELECT 
                movie_id, 
                COUNT(*) AS total_reviews
            FROM 
                movie_info 
            WHERE 
                info_type_id = (SELECT id FROM info_type WHERE info = 'Review')
            GROUP BY 
                movie_id
        ) reviews ON rm.id = reviews.movie_id
    WHERE 
        rm.actor_count > 5
)
SELECT 
    ft.title,
    ft.production_year,
    ft.actor_count,
    ft.total_reviews,
    CASE 
        WHEN ft.total_reviews > 10 THEN 'Highly Reviewed'
        ELSE 'Less Reviewed'
    END AS review_status
FROM 
    FilteredTitles ft
WHERE 
    ft.production_year >= 2000
ORDER BY 
    ft.production_year DESC,
    ft.actor_count DESC;
