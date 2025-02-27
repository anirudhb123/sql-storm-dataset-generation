WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank,
        COUNT(*) OVER (PARTITION BY a.production_year) as movie_count
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.movie_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title, 
        c.person_id,
        c.role_id,
        co.kind as company_type,
        mi.info as movie_info,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') as keyword
    FROM 
        TopMovies t
    LEFT JOIN 
        complete_cast cc ON t.title = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.title
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.title
    LEFT JOIN 
        company_type co ON mc.company_type_id = co.id
    LEFT JOIN 
        movie_info mi ON t.title = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.title = mk.movie_id
    WHERE 
        (c.role_id IS NULL OR c.role_id IN (SELECT id FROM role_type WHERE role LIKE 'Actor%'))
)
SELECT 
    md.title,
    md.production_year,
    COUNT(DISTINCT md.person_id) AS actor_count,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.movie_info, ', ') AS related_info
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year
HAVING 
    COUNT(DISTINCT md.person_id) > 0
ORDER BY 
    md.production_year DESC, actor_count DESC;
