WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_ranked_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank = 1
),
companies_with_movies AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
detailed_movies AS (
    SELECT 
        t.title,
        COALESCE(t.production_year, 0) AS prod_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ARRAY_AGG(DISTINCT c.company_name) AS companies
    FROM 
        top_ranked_movies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        companies_with_movies cm ON tm.movie_id = cm.movie_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info='summary' LIMIT 1)
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    d.title, 
    d.prod_year, 
    d.keywords, 
    COALESCE(d.companies, ARRAY['No companies associated']) AS associated_companies,
    (SELECT COUNT(*) FROM aka_name an WHERE an.name = d.title) AS name_count
FROM 
    detailed_movies d
ORDER BY 
    d.prod_year DESC, d.title;
