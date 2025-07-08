WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        (SELECT movie_id, person_id, nr_order 
         FROM cast_info 
         WHERE role_id = (SELECT id FROM role_type WHERE role = 'actor')) ci ON ci.movie_id = t.id
    GROUP BY 
        t.title, t.production_year
),
ProductionYearStats AS (
    SELECT 
        production_year,
        SUM(actor_count) AS total_actors,
        SUM(keyword_count) AS total_keywords,
        COUNT(title) AS movie_count
    FROM 
        MovieStats
    GROUP BY 
        production_year
),
YearlyAverage AS (
    SELECT 
        production_year,
        AVG(total_actors) AS avg_actors,
        AVG(total_keywords) AS avg_keywords
    FROM 
        ProductionYearStats
    GROUP BY 
        production_year
)
SELECT 
    y.production_year,
    y.avg_actors,
    y.avg_keywords,
    COALESCE(y.avg_actors, 0) - COALESCE(y2.avg_actors, 0) AS actors_difference,
    COALESCE(y.avg_keywords, 0) - COALESCE(y2.avg_keywords, 0) AS keywords_difference
FROM 
    YearlyAverage y
FULL OUTER JOIN 
    YearlyAverage y2 ON y.production_year = y2.production_year - 1
ORDER BY 
    y.production_year;
