WITH RECURSIVE TopActors AS (
    -- Recursive CTE to find the top actors based on movie count
    SELECT
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.person_id
    ORDER BY
        movie_count DESC
    LIMIT 10
),
MovieDetails AS (
    -- CTE to gather detailed movie information including keywords and companies associated
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(mk.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
    HAVING 
        actor_count > 5
),
ActorRatings AS (
    -- CTE for getting actor ratings using window function
    SELECT 
        ak.name,
        COALESCE(SUM(mo.info::numeric), 0) AS total_rating,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(mo.info::numeric), 0) DESC) AS rank
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_info mo ON ci.movie_id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        ak.id
)
-- Final select statement combining results from all CTEs
SELECT 
    ta.person_id,
    ROUND(ar.total_rating, 2) AS average_rating,
    md.title,
    md.production_year,
    md.keywords,
    md.companies
FROM 
    TopActors ta
LEFT JOIN 
    ActorRatings ar ON ta.person_id = ar.person_id
LEFT JOIN 
    MovieDetails md ON ar.rank <= 5   -- Select movies related to top actors
WHERE 
    ar.total_rating IS NOT NULL
ORDER BY 
    average_rating DESC;
