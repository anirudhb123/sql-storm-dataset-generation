WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
), 
award_winners AS (
    SELECT 
        m.title,
        m.production_year,
        r.kind AS award_type,
        COUNT(1) AS award_count
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        info_type i ON mi.info_type_id = i.id
    JOIN 
        role_type r ON i.id = r.id
    WHERE 
        r.role ILIKE '%winner%'
    GROUP BY 
        m.title, m.production_year, r.kind
)
SELECT 
    r.title,
    r.production_year,
    r.cast_count,
    COALESCE(a.award_count, 0) AS awards,
    CASE 
        WHEN r.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS category
FROM 
    ranked_movies r
LEFT JOIN 
    award_winners a ON r.title = a.title AND r.production_year = a.production_year
ORDER BY 
    r.production_year DESC, r.cast_count DESC;
