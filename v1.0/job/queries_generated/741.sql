WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalReport AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        c.name AS top_cast_member,
        TYPE.name AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type TYPE ON mc.company_type_id = TYPE.id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.title, tm.production_year, mk.keywords, c.name, TYPE.name
)
SELECT 
    title,
    production_year,
    keywords,
    top_cast_member,
    COALESCE(company_count, 0) AS company_count
FROM 
    FinalReport
ORDER BY 
    production_year DESC, title;
