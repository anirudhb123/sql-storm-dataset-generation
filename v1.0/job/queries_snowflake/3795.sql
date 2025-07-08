
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_companies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.companies, 'No companies') AS companies,
    COALESCE(mc.company_types, 'No company types') AS company_types
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
