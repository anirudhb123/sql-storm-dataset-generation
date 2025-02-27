WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMoviesByYear AS (
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
        STRING_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No Companies') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
AggregateInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mc.companies, 'No Companies') AS companies
    FROM 
        TopMoviesByYear m
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON m.movie_id = mc.movie_id
)
SELECT 
    ai.title,
    ai.production_year,
    ai.keywords,
    ai.companies,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = ai.movie_id AND mi.info_type_id = 1
        ) THEN 'Has IMDb info'
        ELSE 'No IMDb info'
    END AS imdb_status,
    (SELECT 
        COUNT(*) 
     FROM 
        complete_cast cc 
     WHERE 
        cc.movie_id = ai.movie_id AND cc.status_id IS NULL) AS incomplete_cast_count
FROM 
    AggregateInfo ai
WHERE 
    ai.production_year > 2000
ORDER BY 
    ai.production_year DESC, LENGTH(ai.title) ASC;
