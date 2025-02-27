WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        AVG(COALESCE(movie_info.info, '0')::numeric) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY AVG(COALESCE(movie_info.info, '0')::numeric) DESC) AS rank
    FROM 
        title
    LEFT JOIN movie_info ON title.id = movie_info.movie_id AND movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        title.id
),
ActorRoles AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN rt.role = 'lead' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.id, ak.name
),
TopActors AS (
    SELECT 
        actor_id,
        name,
        movie_count,
        lead_roles,
        DENSE_RANK() OVER (ORDER BY movie_count DESC, lead_roles DESC) AS actor_rank
    FROM 
        ActorRoles
    WHERE 
        movie_count > 5
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.avg_rating,
    ta.name AS lead_actor
FROM 
    RankedMovies rm
JOIN movie_companies mc ON rm.movie_id = mc.movie_id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
LEFT JOIN TopActors ta ON ta.actor_id = (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id ORDER BY ci.nr_order LIMIT 1)
WHERE 
    rm.rank <= 5
    AND rm.avg_rating >= 7.0
ORDER BY 
    rm.avg_rating DESC, rm.title;
