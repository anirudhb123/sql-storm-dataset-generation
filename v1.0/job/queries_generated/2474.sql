WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.rank <= 5
    GROUP BY 
        m.title, m.production_year
),
CompleteMovieData AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        MoviesWithKeywords mw
    LEFT JOIN 
        movie_companies mc ON mw.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    GROUP BY 
        mw.title, mw.production_year, mw.keywords
)

SELECT 
    cmd.title,
    cmd.production_year,
    cmd.keywords,
    cmd.company_count,
    COALESCE((
        SELECT COUNT(*) 
        FROM complete_cast cc 
        WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = cmd.title AND production_year = cmd.production_year)
        AND cc.status_id IS NOT NULL
    ), 0) AS complete_cast_count
FROM 
    CompleteMovieData cmd
WHERE 
    cmd.company_count > 0
ORDER BY 
    cmd.production_year DESC, cmd.company_count DESC;
