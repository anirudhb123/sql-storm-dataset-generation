WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS ranking,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieStats AS (
    SELECT 
        m.title_id, 
        m.title,
        COALESCE(AVG(mi.info::NUMERIC), 0) AS avg_rating,
        COALESCE(MAX(mi.info), 'Not Available') AS highest_rating,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_companies mc ON m.title_id = mc.movie_id
    GROUP BY 
        m.title_id, m.title
),
UnusualRatings AS (
    SELECT 
        title_id,
        title,
        avg_rating,
        highest_rating,
        production_companies,
        CASE 
            WHEN avg_rating > 7 THEN 'High'
            WHEN avg_rating BETWEEN 5 AND 7 THEN 'Medium'
            ELSE 'Low'
        END AS rating_category,
        CASE
            WHEN production_companies IS NULL THEN 'No Production Company'
            ELSE 'Production Company Exists'
        END AS production_company_status
    FROM 
        MovieStats
),
FinalResults AS (
    SELECT 
        u.title_id,
        u.title,
        u.avg_rating,
        u.highest_rating,
        u.rating_category,
        u.production_company_status,
        RANK() OVER (ORDER BY u.avg_rating DESC NULLS LAST) AS rank_by_rating
    FROM 
        UnusualRatings u
)
SELECT 
    f.title_id,
    f.title,
    f.avg_rating,
    f.highest_rating,
    f.rating_category,
    f.production_company_status,
    CASE 
        WHEN f.rank_by_rating <= 10 THEN 'Top Rated'
        ELSE 'Not Top Rated'
    END AS top_rating_status
FROM 
    FinalResults f
WHERE 
    f.rating_category = 'High'
    OR EXISTS (
        SELECT 1 FROM cast_info ci 
        WHERE ci.movie_id = f.title_id AND ci.nr_order = 1
    )
ORDER BY 
    f.avg_rating DESC, f.title;
