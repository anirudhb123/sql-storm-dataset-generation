
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
DetailedInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.num_cast,
        COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
        COALESCE(ci.companies, 'No Companies') AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.production_year = mk.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.production_year = ci.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    movie_title,
    production_year,
    num_cast,
    keywords,
    companies
FROM 
    DetailedInfo
ORDER BY 
    production_year DESC, num_cast DESC;
