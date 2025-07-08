WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title t 
    JOIN 
        movie_info mi ON t.id = mi.movie_id 
    JOIN 
        complete_cast cc ON t.id = cc.movie_id 
    JOIN 
        cast_info ci ON ci.movie_id = t.id 
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        m.title, 
        m.production_year, 
        a.name AS actor_name, 
        k.keyword, 
        mk.id AS movie_keyword_id,
        CASE 
            WHEN k.keyword IS NULL THEN 'No keyword'
            ELSE k.keyword
        END AS keyword_status
    FROM 
        RankedMovies m 
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.title_id 
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id 
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.title_id 
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id 
    WHERE 
        m.rank_by_cast_size <= 3 
    AND 
        m.production_year > 2000 
),
CompaniesWithMoreThanOneMovie AS (
    SELECT 
        mc.company_id, 
        mc.company_type_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc 
    GROUP BY 
        mc.company_id, mc.company_type_id
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 1
),
FinalResults AS (
    SELECT 
        md.title, 
        md.production_year, 
        md.actor_name, 
        md.keyword_status, 
        c.name AS company_name
    FROM 
        MovieDetails md 
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT m.title_id FROM RankedMovies m WHERE m.title = md.title AND m.production_year = md.production_year LIMIT 1)
    LEFT JOIN 
        company_name c ON mc.company_id = c.id 
    WHERE 
        c.id IN (SELECT company_id FROM CompaniesWithMoreThanOneMovie)
)
SELECT 
    title,
    production_year,
    actor_name,
    keyword_status,
    COALESCE(company_name, 'Independent') AS company_name
FROM 
    FinalResults
WHERE 
    (LOWER(keyword_status) LIKE '%keyword%' OR keyword_status = 'No keyword')
ORDER BY 
    production_year DESC, 
    actor_name;
