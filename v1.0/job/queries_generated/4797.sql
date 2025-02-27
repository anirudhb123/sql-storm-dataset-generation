WITH MovieRoleInfo AS (
    SELECT 
        m.title AS movie_title,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER(PARTITION BY m.id ORDER BY c.nr_order) AS role_order
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
),
ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        MovieRoleInfo
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) > 5
),
KeywordMovieInfo AS (
    SELECT 
        m.title AS movie_title,
        k.keyword AS keyword
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
),
CompanyMovieInfo AS (
    SELECT 
        m.title AS movie_title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    DISTINCT m.movie_title,
    COALESCE(a.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(k.keyword, 'No Keyword') AS keyword,
    COALESCE(c.company_name, 'Independent') AS company_name,
    mc.movie_count
FROM 
    KeywordMovieInfo k
FULL OUTER JOIN 
    MovieRoleInfo m ON k.movie_title = m.movie_title
FULL OUTER JOIN 
    ActorMovieCount mc ON m.actor_name = mc.actor_name
FULL OUTER JOIN 
    CompanyMovieInfo c ON m.movie_title = c.movie_title
WHERE 
    (m.role_order IS NOT NULL OR mc.movie_count IS NOT NULL)
    AND (k.keyword IS NOT NULL OR c.company_name IS NOT NULL)
ORDER BY 
    m.movie_title, actor_name;
