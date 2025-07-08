
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COALESCE(COUNT(DISTINCT ci.id), 0) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

CompanyDetails AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        COALESCE(MIN(ct.kind), 'Unknown') AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),

MovieStats AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.cast_count,
        c.companies,
        c.company_type,
        CASE 
            WHEN md.cast_count = 0 THEN 'No cast available'
            WHEN md.year_rank <= 5 THEN 'Top 5 in year'
            ELSE 'Regular Movie'
        END AS movie_category
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails c ON md.movie_id = c.movie_id
)

SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    cast_count,
    companies,
    company_type,
    movie_category,
    (SELECT AVG(cast_count) 
        FROM MovieStats mst 
        WHERE mst.production_year = ms.production_year) AS avg_cast_count_per_year
FROM 
    MovieStats ms
WHERE 
    (production_year >= 1990 AND production_year < 2020)
    OR (keyword IS NOT NULL AND cast_count > 0)
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 50;
