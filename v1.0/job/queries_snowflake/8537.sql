
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank_order
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        company_name,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rank_order = 1
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.company_name,
    LISTAGG(tr.keyword, ', ') WITHIN GROUP (ORDER BY tr.keyword) AS keywords
FROM 
    TopRankedMovies tr
GROUP BY 
    tr.movie_id, tr.title, tr.company_name
ORDER BY 
    tr.title ASC;
