WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
popular_titles AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        year_rank = 1
),
company_info AS (
    SELECT 
        cn.name AS company_name,
        ct.kind AS company_type,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    pt.title,
    pt.production_year,
    COALESCE(cic.company_name, 'Independent') AS production_company,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(rm.cast_count, 0) AS cast_count
FROM 
    popular_titles pt
LEFT JOIN 
    company_info cic ON pt.title = cic.movie_id
LEFT JOIN 
    movie_keyword_counts mkc ON pt.title = mkc.movie_id
LEFT JOIN 
    (SELECT 
         at.movie_id,
         COUNT(DISTINCT ci.person_id) AS cast_count
     FROM 
         aka_title at
     JOIN 
         cast_info ci ON at.movie_id = ci.movie_id
     GROUP BY 
         at.movie_id) rm ON pt.title = rm.movie_id
WHERE 
    (pt.production_year >= 2010 OR pt.production_year IS NULL)
ORDER BY 
    pt.production_year DESC, pt.title;
