WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        a.person_id, ak.name
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        R.movie_id,
        R.title,
        R.production_year,
        R.year_rank,
        COALESCE(M.company_names, 'No Companies') AS company_names,
        COALESCE(A.movie_count, 0) AS actor_count
    FROM 
        RecursiveMovieCTE R
    LEFT JOIN 
        MovieCompanyInfo M ON R.movie_id = M.movie_id
    LEFT JOIN 
        ActorInfo A ON A.person_id IN (
            SELECT person_id 
            FROM cast_info 
            WHERE movie_id = R.movie_id
        )
)
SELECT 
    FM.title,
    FM.production_year,
    FM.company_names,
    FM.actor_count,
    MKT.keyword AS movie_keyword,
    (CASE 
        WHEN FM.actor_count > 10 THEN 'Ensemble Cast'
        WHEN FM.actor_count = 0 THEN 'No Cast'
        ELSE 'Moderate Cast'
    END) AS cast_type
FROM 
    FilteredMovies FM
LEFT JOIN 
    movie_keyword MKT ON FM.movie_id = MKT.movie_id
ORDER BY 
    FM.production_year DESC, 
    FM.year_rank ASC
LIMIT 100;
