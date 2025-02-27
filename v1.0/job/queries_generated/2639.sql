WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.title, t.production_year, t.kind_id
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year, k.keyword
),
PopularCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(mc.company_id) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, c.name
    HAVING 
        COUNT(mc.company_id) > 1
),
CombinedResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        pc.company_name,
        rm.movie_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MoviesWithKeywords mk ON rm.title = mk.title AND rm.production_year = mk.production_year
    LEFT JOIN 
        PopularCompanies pc ON rm.movie_rank <= 5 AND rm.movie_rank = pc.movie_id
)
SELECT 
    title,
    production_year,
    keyword,
    company_name,
    movie_rank
FROM 
    CombinedResults
WHERE
    production_year >= 2000 AND
    (keyword IS NOT NULL OR company_name IS NULL)
ORDER BY 
    movie_rank ASC, production_year DESC;
