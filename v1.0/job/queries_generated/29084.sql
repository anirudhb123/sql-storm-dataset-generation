WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count,
        keywords,
        actors,
        companies
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.keyword_count,
    t.keywords,
    t.actors,
    t.companies,
    COALESCE(pg.info, 'No information') AS production_info,
    COALESCE(pi.info, 'No personal info') AS personal_info
FROM 
    TopMovies t
LEFT JOIN 
    movie_info pg ON t.movie_id = pg.movie_id AND pg.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Company' LIMIT 1)
LEFT JOIN 
    person_info pi ON EXISTS (
        SELECT 1
        FROM cast_info ci
        WHERE ci.movie_id = t.movie_id 
        AND ci.person_id = pi.person_id
    )
ORDER BY 
    t.production_year DESC, 
    t.keyword_count DESC;
