WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS actor_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
),
MovieCompaniesCTE AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieWithNulls AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        mcc.company_count,
        mcc.company_names
    FROM 
        RankedMovies tm
    LEFT JOIN 
        MovieCompaniesCTE mcc ON tm.rank_by_year = mcc.movie_id
    WHERE 
        tm.movie_keyword IS NULL OR mcc.company_count IS NULL
)
SELECT 
    am.name AS actor_name,
    mw.movie_title,
    mw.production_year,
    mw.company_count,
    mw.company_names
FROM 
    ActorMovies am
JOIN 
    MovieWithNulls mw ON am.movie_id = mw.company_count  -- Bizarre join logic on company_count
WHERE 
    (mw.company_names IS NOT NULL OR mw.company_count > 3) -- Complicated predicates with OR logic
    AND am.actor_movie_rank <= 5  -- Filter for top 5 movies per actor
ORDER BY 
    mw.production_year DESC, 
    am.name ASC;
