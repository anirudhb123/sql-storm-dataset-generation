
WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        RANK() OVER (PARTITION BY a.production_year ORDER BY mt.info_type_id) AS rank_per_year,
        a.movie_id
    FROM 
        aka_title AS a
    JOIN 
        movie_info AS mt ON a.movie_id = mt.movie_id
    WHERE 
        a.production_year >= 2000
        AND mt.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.rank_per_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_names, 'No Companies') AS company_names
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieKeywords AS mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies AS mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank_per_year ASC;
