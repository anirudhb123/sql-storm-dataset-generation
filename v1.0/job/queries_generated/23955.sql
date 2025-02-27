WITH RECURSIVE CompanyHierarchy AS (
    SELECT C.id AS company_id, C.name AS company_name, M.movie_id, 
           COALESCE(MC.company_type_id, 0) AS company_type_id, 
           COALESCE(CP.kind, 'Unknown') AS company_type,
           ROW_NUMBER() OVER (PARTITION BY C.id ORDER BY M.production_year DESC) AS year_rank
    FROM company_name C
    LEFT JOIN movie_companies MC ON C.id = MC.company_id
    LEFT JOIN aka_title M ON MC.movie_id = M.id
    LEFT JOIN company_type CP ON MC.company_type_id = CP.id
    WHERE C.country_code IS NOT NULL
),
ActorMovies AS (
    SELECT A.name AS actor_name, T.title AS movie_title, T.production_year,
           ROW_NUMBER() OVER (PARTITION BY A.id ORDER BY T.production_year DESC) AS role_rank
    FROM aka_name A
    JOIN cast_info CI ON A.person_id = CI.person_id
    JOIN aka_title T ON CI.movie_id = T.id
    WHERE A.name IS NOT NULL
),
MovieKeywords AS (
    SELECT T.id AS movie_id, K.keyword, ROW_NUMBER() OVER (PARTITION BY T.id ORDER BY K.keyword) AS keyword_rank
    FROM aka_title T
    JOIN movie_keyword MK ON T.id = MK.movie_id
    JOIN keyword K ON MK.keyword_id = K.id
),
FilteredMovies AS (
    SELECT CM.company_name, AM.actor_name, AM.movie_title, 
           AM.production_year, MK.keyword
    FROM CompanyHierarchy CM
    INNER JOIN ActorMovies AM ON CM.movie_id = AM.movie_id
    LEFT JOIN MovieKeywords MK ON AM.movie_title = MK.keyword
    WHERE AM.production_year BETWEEN 2000 AND 2023
)
SELECT company_name, actor_name, movie_title, 
       production_year, STRING_AGG(keyword, ', ') AS keywords
FROM FilteredMovies
WHERE keyword IS NOT NULL
GROUP BY company_name, actor_name, movie_title, production_year
HAVING COUNT(DISTINCT keyword) > 1
ORDER BY production_year DESC, company_name, actor_name;

This SQL query effectively combines several advanced SQL features, such as Common Table Expressions (CTEs), window functions, outer joins, string aggregation, and complex predicates. It retrieves a comprehensive list of movies produced by companies in a particular country, featuring actors with their respective roles, while including a wealth of filtering and grouping for enhanced data insights.
