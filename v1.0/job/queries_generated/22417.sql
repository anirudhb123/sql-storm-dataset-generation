WITH RecursiveTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        CASE
            WHEN t.production_year IS NULL THEN 'Unknown Year'
            WHEN t.production_year < 2000 THEN 'Prior to 2000'
            WHEN t.production_year BETWEEN 2000 AND 2010 THEN '2000s'
            ELSE '2011 and Beyond'
        END AS production_period,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title AS t
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_order
    FROM
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
),
TitleKwords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mt
    JOIN 
        keyword AS kw ON mt.keyword_id = kw.id
    GROUP BY 
        mt.movie_id
),
CastingDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.role_id,
        ct.kind AS role_description,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS ct ON ci.role_id = ct.id
),
AggregateMovieInfo AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(CD.company_name, 'Independent') AS production_company,
        COALESCE(TK.keywords, 'No Keywords') AS associated_keywords,
        COUNT(DISTINCT CD.company_name) AS num_companies,
        COUNT(DISTINCT CA.actor_name) AS num_actors
    FROM 
        RecursiveTitles AS t
    LEFT JOIN 
        CompanyDetails AS CD ON t.title_id = CD.movie_id
    LEFT JOIN 
        TitleKwords AS TK ON t.title_id = TK.movie_id
    LEFT JOIN 
        CastingDetails AS CA ON t.title_id = CA.movie_id
    GROUP BY 
        t.title, t.production_year, CD.company_name, TK.keywords
)
SELECT 
    *,
    CASE
        WHEN num_companies > 5 THEN 'Big Studio'
        WHEN num_companies BETWEEN 2 AND 5 THEN 'Medium Studio'
        ELSE 'Small or Independent Studio'
    END AS studio_category,
    CASE
        WHEN num_actors < 1 THEN 'Unknown Cast'
        ELSE 'Cast Available'
    END AS cast_availability,
    COALESCE(NULLIF(CAST(num_actors AS VARCHAR), '0'), 'No Actors') AS actors_status
FROM 
    AggregateMovieInfo
WHERE
    production_company IS NOT NULL
ORDER BY 
    production_period, title
LIMIT 100;
