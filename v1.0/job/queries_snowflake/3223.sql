
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM
        aka_title t
        LEFT JOIN cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
        JOIN keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieIndustryInfo AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    mk.keywords,
    mi.company_name,
    mi.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieIndustryInfo mi ON tm.movie_id = mi.movie_id
WHERE 
    tm.production_year BETWEEN 1990 AND 2000
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
