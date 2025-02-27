WITH ActorMovieInfo AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    JOIN movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.name IS NOT NULL
    GROUP BY a.name, t.title, t.production_year
),
CompanyMovieInfo AS (
    SELECT 
        c.name AS company_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(m.id) AS company_movies_count
    FROM company_name c
    JOIN movie_companies m ON c.id = m.company_id
    JOIN aka_title t ON m.movie_id = t.movie_id
    WHERE c.name IS NOT NULL
    GROUP BY c.name, t.title, t.production_year
),
CompleteMovieInfo AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.keywords,
        cm.company_name,
        cm.company_movies_count
    FROM ActorMovieInfo am
    LEFT JOIN CompanyMovieInfo cm ON am.movie_title = cm.movie_title AND am.production_year = cm.production_year
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(keywords, 'No keywords') AS keywords,
    COALESCE(company_name, 'Independent') AS production_company,
    COALESCE(company_movies_count, 0) AS number_of_movies_by_company
FROM CompleteMovieInfo
ORDER BY production_year DESC, actor_name, movie_title;
