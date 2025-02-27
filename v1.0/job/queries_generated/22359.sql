WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title AS mt
),
ActorsWithMovies AS (
    SELECT 
        aks.id AS actor_id,
        aks.name AS actor_name,
        c.movie_id,
        RANK() OVER (PARTITION BY aks.id ORDER BY c.nr_order) AS movie_rank
    FROM 
        aka_name AS aks
    INNER JOIN 
        cast_info AS c ON aks.person_id = c.person_id
    INNER JOIN 
        RankedMovies AS rm ON c.movie_id = rm.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword AS mk
    INNER JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    INNER JOIN 
        company_name AS cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
),
CompleteMovieInfo AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        COALESCE(mk.all_keywords, 'None') AS keywords,
        COALESCE(ci.company_name, 'Independent') AS production_company,
        COALESCE(ci.company_type, 'Unknown') AS company_type,
        COALESCE(aks.actor_name, 'No Actor') AS primary_actor
    FROM 
        aka_title AS mt
    LEFT JOIN 
        MovieKeywords AS mk ON mt.id = mk.movie_id
    LEFT JOIN 
        CompanyInfo AS ci ON mt.id = ci.movie_id
    LEFT JOIN 
        ActorsWithMovies AS aks ON mt.id = aks.movie_id AND aks.movie_rank = 1
)
SELECT 
    cmi.title,
    cmi.production_company,
    cmi.company_type,
    cmi.keywords,
    COUNT(DISTINCT aks.actor_id) AS number_of_actors,
    SUM(CASE WHEN mk.all_keywords IS NOT NULL THEN 1 ELSE 0 END) AS has_keywords,
    COUNT(DISTINCT ci.company_name) OVER(PARTITION BY cmi.movie_id) AS distinct_production_companies,
    CASE
        WHEN cmi.keywords = 'None' OR cmi.keywords IS NULL THEN 'No keywords available'
        ELSE cmi.keywords
    END AS keyword_info
FROM 
    CompleteMovieInfo AS cmi
LEFT JOIN 
    cast_info AS aks ON cmi.movie_id = aks.movie_id
GROUP BY 
    cmi.title, cmi.production_company, cmi.company_type, cmi.keywords
HAVING 
    COUNT(DISTINCT aks.actor_id) > 2
ORDER BY 
    cmi.production_company,
    number_of_actors DESC,
    cmi.title;
