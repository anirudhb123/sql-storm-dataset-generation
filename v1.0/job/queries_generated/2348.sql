WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, m.kind_id) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%Drama%'
), 
cast_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(cc.num_cast, 0) AS num_cast,
        (SELECT COUNT(*) FROM movie_info WHERE movie_id = m.movie_id AND info_type_id = 1) AS num_awards
    FROM 
        ranked_movies m
    LEFT JOIN 
        cast_counts cc ON m.movie_id = cc.movie_id
)
SELECT 
    md.title,
    md.num_cast,
    md.num_awards,
    CASE 
        WHEN md.num_awards IS NULL THEN 'No Awards'
        WHEN md.num_awards > 0 THEN 'Awarded'
        ELSE 'Not Awarded'
    END AS award_status
FROM 
    movie_details md
WHERE 
    md.rank <= 5
ORDER BY 
    md.num_cast DESC, md.production_year DESC;
