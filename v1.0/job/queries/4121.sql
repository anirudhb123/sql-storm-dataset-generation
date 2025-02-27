WITH MovieStatistics AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
RatingInfo AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS highest_rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info = 'rating'
    GROUP BY 
        mi.movie_id
)
SELECT 
    ms.title_id,
    ms.title,
    ms.production_year,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    ms.total_cast,
    ms.avg_order,
    COALESCE(ri.highest_rating, 'N/A') AS highest_rating
FROM 
    MovieStatistics ms
LEFT JOIN 
    KeywordStats ks ON ms.title_id = ks.movie_id
LEFT JOIN 
    RatingInfo ri ON ms.title_id = ri.movie_id
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC,
    ms.total_cast DESC,
    ms.avg_order ASC;
