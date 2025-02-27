WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS director_name,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank
    FROM 
        aka_title a
    INNER JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    INNER JOIN 
        movie_companies mc ON a.id = mc.movie_id
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id 
    INNER JOIN 
        cast_info ci ON a.id = ci.movie_id 
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id 
    INNER JOIN 
        role_type r ON ci.role_id = r.id 
    WHERE 
        r.role IN ('Director', 'Producer')
    GROUP BY 
        a.title, a.production_year, c.name
),
MostPopularTitles AS (
    SELECT 
        movie_title,
        production_year,
        director_name,
        keyword_count
    FROM 
        RankedTitles
    WHERE 
        rank = 1
)
SELECT 
    movie_title,
    production_year,
    director_name,
    keyword_count,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = mt.production_year) AS total_movies_in_year
FROM 
    MostPopularTitles mt
ORDER BY 
    production_year DESC, keyword_count DESC;
