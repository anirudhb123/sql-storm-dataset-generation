WITH RECURSIVE movie_recursive AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num
    FROM 
        aka_title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        m.id, t.title, t.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_companies_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rc.movie_id,
    rc.title,
    rc.production_year,
    rc.total_cast,
    mk.keywords,
    mci.company_names
FROM 
    movie_recursive rc
LEFT JOIN 
    movie_keywords mk ON rc.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies_info mci ON rc.movie_id = mci.movie_id
WHERE 
    rc.total_cast > 5
AND 
    rc.production_year BETWEEN 1990 AND 2023
ORDER BY 
    rc.production_year DESC, rc.total_cast DESC;
