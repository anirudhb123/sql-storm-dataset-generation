WITH RecursiveCTE AS (
    SELECT 
        ct.id AS cast_info_id,
        ct.person_id,
        ct.movie_id,
        ct.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ct.movie_id ORDER BY ct.nr_order) AS role_order
    FROM 
        cast_info ct
    WHERE 
        ct.nr_order IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT rc.movie_id) AS total_movies,
        AVG(CASE WHEN co.prod_year IS NOT NULL THEN co.prod_year ELSE 0 END) AS avg_production_year
    FROM 
        aka_name a
    LEFT JOIN 
        RecursiveCTE rc ON a.person_id = rc.person_id
    LEFT JOIN 
        aka_title at ON rc.movie_id = at.id
    LEFT JOIN (
        SELECT
            movie_id,
            MIN(production_year) AS prod_year
        FROM 
            aka_title
        GROUP BY 
            movie_id
    ) co ON rc.movie_id = co.movie_id
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
    GROUP BY 
        a.id, a.name
),
TitleInfo AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    GROUP BY 
        at.title, at.production_year
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalMetrics AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        am.total_movies,
        am.avg_production_year,
        tc.title,
        tc.total_companies,
        kc.keyword_count
    FROM 
        ActorMovies am
    JOIN 
        TitleInfo tc ON am.total_movies > 5
    LEFT JOIN 
        KeywordCount kc ON am.total_movies > kc.keyword_count
    WHERE 
        am.avg_production_year > (
            SELECT 
                AVG(avg_production_year) 
            FROM 
                ActorMovies
            WHERE 
                total_movies > 0
        )
)

SELECT 
    f.actor_id,
    f.actor_name,
    f.total_movies,
    f.avg_production_year,
    f.title,
    f.total_companies,
    COALESCE(f.keyword_count, 0) AS keyword_count
FROM 
    FinalMetrics f
ORDER BY 
    f.total_movies DESC,
    f.avg_production_year DESC,
    f.keyword_count DESC;
