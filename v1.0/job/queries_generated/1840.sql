WITH RankedMovies AS (
    SELECT 
        a.title,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ci.nr_order) AS actor_rank,
        a.production_year,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.id, a.title, ak.name, a.production_year 
),
FilteredMovies AS (
    SELECT 
        title,
        actor_name,
        actor_rank,
        production_year,
        production_company_count
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND 
        actor_rank <= 3 AND 
        production_company_count > 2
),
KeywordCounts AS (
    SELECT 
        am.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title am
    LEFT JOIN 
        movie_keyword mk ON am.id = mk.movie_id
    GROUP BY 
        am.movie_id
)
SELECT 
    fm.title,
    fm.actor_name,
    fm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    KeywordCounts kc ON fm.id = kc.movie_id
ORDER BY 
    fm.production_year DESC,
    fm.actor_name;
