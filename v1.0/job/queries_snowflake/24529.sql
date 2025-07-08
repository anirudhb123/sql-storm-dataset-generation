
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
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
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords available') AS keywords,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = tm.movie_id 
       AND cc.status_id IS NULL
    ) AS unknown_status_count,
    (SELECT LISTAGG(DISTINCT c.name, ', ') 
     FROM cast_info ci 
     JOIN aka_name c ON ci.person_id = c.person_id 
     WHERE ci.movie_id = tm.movie_id
    ) AS cast_members
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    COALESCE(cn.country_code, 'Unknown') IN ('USA', 'UK', 'France')
    AND NOT EXISTS (SELECT 1 
                    FROM movie_info mi 
                    WHERE mi.movie_id = tm.movie_id 
                      AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
                      AND (mi.info IS NULL OR mi.info = '')
           )
ORDER BY 
    tm.production_year DESC, 
    tm.title;
