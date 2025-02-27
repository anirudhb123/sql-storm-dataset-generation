WITH MovieStats AS (
    SELECT 
        a.title,
        AVG(m.production_year) AS avg_production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        aka_title a
    JOIN 
        movie_info m ON a.movie_id = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.title
),
TopMovies AS (
    SELECT 
        title,
        avg_production_year,
        total_cast,
        total_keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, avg_production_year ASC) AS rank
    FROM 
        MovieStats
    WHERE 
        total_cast > 10
)
SELECT 
    t.title,
    t.avg_production_year,
    t.total_cast,
    t.total_keywords,
    COALESCE(n.name, 'Unknown') AS actor_name,
    CASE 
        WHEN t.total_keywords > 5 THEN 'High'
        WHEN t.total_keywords BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_quality
FROM 
    TopMovies t
LEFT JOIN 
    cast_info ci ON t.title = (SELECT DISTINCT a.title 
                                FROM aka_title a 
                                JOIN movie_companies mc ON a.movie_id = mc.movie_id 
                                WHERE mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')
                                LIMIT 1)
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    t.rank <= 10
ORDER BY 
    t.rank;
