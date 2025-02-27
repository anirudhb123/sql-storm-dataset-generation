WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        kind_id
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        COALESCE(SUBSTRING(m.title FROM 1 FOR POSITION(' ' IN m.title) - 1), 'N/A') AS first_word
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    ct.company_name,
    ct.company_type,
    mk.keyword,
    mk.first_word,
    COALESCE(mk.keyword || ' - Featured', 'No Keyword') AS keyword_label
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails ct ON tm.id = ct.movie_id AND ct.company_rank = 1
LEFT JOIN 
    MovieKeywords mk ON tm.id = mk.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.title;
