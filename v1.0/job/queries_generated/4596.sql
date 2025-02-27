WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM  
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
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
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mk.keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        movie_companies mc ON mwk.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    cmi.movie_id,
    cmi.title,
    cmi.production_year,
    cmi.keywords,
    cmi.company_name,
    COUNT(DISTINCT ci.person_id) AS number_of_cast_members,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS avg_person_info_length
FROM 
    CompleteMovieInfo cmi
LEFT JOIN 
    complete_cast cc ON cmi.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    cast_info ci ON cmi.movie_id = ci.movie_id
GROUP BY 
    cmi.movie_id, cmi.title, cmi.production_year, cmi.keywords, cmi.company_name
ORDER BY 
    cmi.production_year DESC, number_of_cast_members DESC;
