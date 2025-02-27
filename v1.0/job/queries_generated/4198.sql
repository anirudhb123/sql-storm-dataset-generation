WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS title_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularGenres AS (
    SELECT 
        kt.kind AS genre,
        COUNT(mt.id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type kt ON k.phonetic_code = kt.id
    JOIN 
        movie_info mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        kt.kind
    HAVING 
        COUNT(mt.id) > 100
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    pg.genre,
    cm.company_names
FROM 
    RankedTitles rt
JOIN 
    PopularGenres pg ON rt.title_id = pg.movie_count
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, pg.movie_count DESC;
