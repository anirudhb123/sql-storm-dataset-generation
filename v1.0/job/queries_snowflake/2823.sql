
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    GROUP BY 
        at.title, at.production_year
),
TopCastMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        at.title, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords 
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
)
SELECT 
    tcm.title, 
    tcm.production_year, 
    COALESCE(mk.keywords, 'No Keywords') AS keywords 
FROM 
    TopCastMovies tcm
LEFT JOIN 
    MovieKeywords mk ON tcm.title = mk.title
ORDER BY 
    tcm.production_year DESC, 
    tcm.title;
