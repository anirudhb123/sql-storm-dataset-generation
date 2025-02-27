WITH RankedTitles AS (
    SELECT 
        at.title AS MovieTitle,
        at.production_year AS ProductionYear,
        COUNT(DISTINCT ci.person_id) AS CastCount,
        SUM(CASE 
            WHEN ct.kind = 'Director' THEN 1 
            ELSE 0 END) AS DirectorCount,
        SUM(CASE 
            WHEN ct.kind = 'Producer' THEN 1 
            ELSE 0 END) AS ProducerCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS Rank
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT *
    FROM RankedTitles
    WHERE Rank <= 10
),
MovieKeywords AS (
    SELECT 
        tm.MovieTitle,
        STRING_AGG(k.keyword, ', ') AS Keywords
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = tm.MovieTitle LIMIT 1)
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        tm.MovieTitle
)

SELECT 
    tm.MovieTitle,
    tm.ProductionYear,
    tm.CastCount,
    tm.DirectorCount,
    tm.ProducerCount,
    mk.Keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.MovieTitle = mk.MovieTitle
ORDER BY 
    tm.CastCount DESC, tm.MovieTitle;
