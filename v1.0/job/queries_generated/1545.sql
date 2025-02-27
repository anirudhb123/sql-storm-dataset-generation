WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
HighActorMovies AS (
    SELECT 
        title,
        production_year,
        total_actors
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        HighActorMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.keywords, 'No keywords') AS keywords,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM company_name cn 
     INNER JOIN movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = m.title AND production_year = m.production_year)
     WHERE mc.company_id = cn.id 
     AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
    ) AS production_companies
FROM 
    MoviesWithKeywords m
ORDER BY 
    m.production_year DESC, m.title;
