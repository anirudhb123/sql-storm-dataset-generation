
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        pt.kind AS production_type,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT ci.note) AS role_notes
    FROM
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = t.id)
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    JOIN 
        kind_type pt ON t.kind_id = pt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id AND ci.person_id = ak.person_id
    WHERE
        cn.country_code = 'USA' 
        AND t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ak.name, pt.kind
),
ActorRankings AS (
    SELECT 
        actor_name,
        SUM(keyword_count) AS total_keywords,
        COUNT(movie_title) AS movie_count,
        RANK() OVER (ORDER BY SUM(keyword_count) DESC) AS actor_rank
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    total_keywords,
    movie_count,
    actor_rank
FROM 
    ActorRankings
WHERE 
    actor_rank <= 10
ORDER BY 
    total_keywords DESC;
