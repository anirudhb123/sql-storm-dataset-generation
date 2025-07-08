
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.companies, 'No companies') AS companies,
    COALESCE(mc.company_types, 'No company types') AS company_types,
    COALESCE(SUM(ci.nr_order), 0) AS total_cast_order,
    COUNT(DISTINCT ci.person_id) AS unique_cast_count
FROM 
    TopMovies AS tm
LEFT JOIN 
    MovieKeywords AS mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies AS mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    cast_info AS ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords, mc.companies, mc.company_types
HAVING 
    SUM(COALESCE(ci.nr_order, 0)) > 0
ORDER BY 
    tm.production_year DESC, unique_cast_count DESC;
