WITH MovieRankings AS (
    SELECT 
        a.title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE 
            WHEN mi.info IS NULL THEN 0 
            ELSE CAST(mi.info AS numeric) 
        END) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id 
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        actor_count, 
        avg_rating,
        rank
    FROM 
        MovieRankings
    WHERE 
        actor_count > 5
)
SELECT 
    fm.title,
    fm.actor_count,
    fm.avg_rating,
    (SELECT COUNT(*) FROM MovieRankings WHERE rank < fm.rank) AS movies_before,
    CASE 
        WHEN fm.avg_rating >= 7 THEN 'Highly Rated'
        WHEN fm.avg_rating IS NULL THEN 'No Rating Available'
        ELSE 'Average Rated'
    END AS rating_category
FROM 
    FilteredMovies fm
ORDER BY 
    fm.avg_rating DESC, 
    fm.actor_count DESC
LIMIT 10;
