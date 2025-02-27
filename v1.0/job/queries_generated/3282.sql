WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.kind_id IN (SELECT k.id FROM kind_type k WHERE k.kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 3
),
MovieDetails AS (
    SELECT 
        pm.title,
        COALESCE(ki.keyword, 'No Keyword') AS keyword,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        PopularMovies pm
    LEFT JOIN 
        movie_keyword mk ON pm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies mc ON pm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        pm.title, ki.keyword
)
SELECT 
    md.title,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT unnest(md.companies)) > 0 THEN 'Famous Production'
        ELSE 'Unknown Production'
    END AS production_status
FROM 
    MovieDetails md
GROUP BY 
    md.title
HAVING 
    COUNT(DISTINCT md.keyword) > 1
ORDER BY 
    md.title ASC;
