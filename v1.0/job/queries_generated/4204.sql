WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        TopMovies m
    LEFT JOIN 
        MovieKeywords mk ON m.title = mk.movie_id 
    LEFT JOIN 
        movie_info mi ON m.production_year = mi.movie_id 
)
SELECT 
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.additional_info,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    MovieInfo mi
LEFT JOIN 
    movie_companies mc ON mi.production_year = mc.movie_id 
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id 
LEFT JOIN 
    complete_cast cc ON mi.production_year = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
GROUP BY 
    mi.title, mi.production_year, mi.keywords, mi.additional_info, cn.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mi.production_year DESC, mi.title;
