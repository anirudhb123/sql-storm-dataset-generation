WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        ak.name AS actor_name,
        c.person_role_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_rank,
        a.production_year,
        k.keyword AS keyword,
        r.role AS actor_role
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN role_type r ON c.role_id = r.id
    WHERE a.production_year >= 2000 
      AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
      AND ak.name IS NOT NULL
),
HighlightedActors AS (
    SELECT 
        movie_title,
        actor_name,
        actor_rank,
        production_year,
        STRING_AGG(keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_role, ', ') AS roles
    FROM RankedMovies
    WHERE actor_rank <= 5
    GROUP BY movie_title, actor_name, actor_rank, production_year
),
FinalAnalysis AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS number_of_actors,
        AVG(production_year) AS avg_production_year,
        STRING_AGG(keywords, '; ') AS all_keywords,
        STRING_AGG(roles, '; ') AS all_roles
    FROM HighlightedActors
    GROUP BY movie_title
)

SELECT 
    movie_title,
    number_of_actors,
    avg_production_year,
    all_keywords,
    all_roles
FROM FinalAnalysis
ORDER BY number_of_actors DESC, avg_production_year ASC;
