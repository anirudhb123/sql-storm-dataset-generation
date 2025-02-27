
WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT m.company_id) AS total_companies,
        AVG(COALESCE(CAST(mi.info AS FLOAT), 0)) AS avg_info_rating
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        t.title, t.production_year
), PopularityRanked AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.total_companies,
        ms.avg_info_rating,
        RANK() OVER (ORDER BY ms.avg_info_rating DESC, ms.total_cast DESC) AS popularity_rank
    FROM 
        MovieStats ms
), FilteredMovies AS (
    SELECT 
        pr.movie_title,
        pr.production_year,
        pr.total_cast,
        pr.total_companies,
        pr.avg_info_rating,
        pr.popularity_rank
    FROM 
        PopularityRanked pr
    WHERE 
        pr.total_cast >= 5 AND pr.avg_info_rating IS NOT NULL
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.total_cast,
    fm.total_companies,
    fm.avg_info_rating,
    (CASE 
        WHEN fm.popularity_rank <= 10 THEN 'Top 10 Movies'
        WHEN fm.popularity_rank <= 50 THEN 'Top 50 Movies'
        ELSE 'Other Movies' 
    END) AS movie_category
FROM 
    FilteredMovies fm
ORDER BY 
    fm.popularity_rank;
