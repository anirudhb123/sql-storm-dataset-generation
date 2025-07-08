
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS ranking
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        ranking <= 5
),
CompanyMovieInfo AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('box office', 'budget'))
    GROUP BY 
        m.title, c.name, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    cmi.company_name,
    cmi.company_type,
    COALESCE(cmi.keywords, 'No Keywords') AS keywords_info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovieInfo cmi ON tm.title = cmi.title
ORDER BY 
    tm.production_year, tm.title;
