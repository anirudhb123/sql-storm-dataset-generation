
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title AS a
    LEFT JOIN 
        movie_companies AS mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info AS ci ON a.id = ci.movie_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.title IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year, c.name
),

favorite_companies AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT ci.person_id) AS popular_cast
    FROM 
        movie_companies AS mc
    JOIN 
        cast_info AS ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.company_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),

movie_details AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.company_name,
        rm.cast_count,
        CASE 
            WHEN rm.rank_within_year <= 3 THEN 'Top Movie'
            ELSE 'Regular Movie'
        END AS movie_category
    FROM 
        ranked_movies AS rm
    JOIN 
        favorite_companies AS fc ON rm.company_name = (SELECT name FROM company_name WHERE id = fc.company_id)
)

SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.cast_count,
    md.movie_category,
    COALESCE(array_to_string(ARRAY_AGG(DISTINCT k.keyword), ', '), 'No Keywords') AS keywords
FROM 
    movie_details AS md
LEFT JOIN 
    movie_keyword AS mk ON md.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
GROUP BY 
    md.movie_title, md.production_year, md.company_name, md.cast_count, md.movie_category
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
