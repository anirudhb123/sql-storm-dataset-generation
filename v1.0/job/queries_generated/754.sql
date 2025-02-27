WITH movie_rankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_awards AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS award_count
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY 
        m.id
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.num_cast,
    ma.award_count,
    CASE 
        WHEN mr.rank <= 3 THEN 'Top 3'
        ELSE 'Others'
    END AS ranking_category
FROM 
    movie_rankings mr
LEFT JOIN 
    movie_awards ma ON mr.movie_id = ma.movie_id
WHERE 
    ma.award_count > 0 OR mr.num_cast > 5
ORDER BY 
    mr.production_year DESC, ranking_category, mr.num_cast DESC;
