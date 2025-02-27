WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordPopularity AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
),
FinalResults AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        a.name AS actor_name,
        a.movie_count,
        c.company_name,
        c.company_type,
        k.keyword,
        k.keyword_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorInfo a ON r.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = a.person_id)
    LEFT JOIN 
        CompanyDetails c ON r.movie_id = c.movie_id
    LEFT JOIN 
        KeywordPopularity k ON r.movie_id = k.movie_id
    WHERE 
        r.title_rank <= 10
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    movie_count,
    company_name,
    company_type,
    keyword,
    keyword_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title;
