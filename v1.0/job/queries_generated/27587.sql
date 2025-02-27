WITH ActorMovieCounts AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorMovieCounts
    WHERE 
        movie_count > 5
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    ak.name AS actor_name,
    ak.id AS actor_id,
    k.keyword AS keyword,
    ct.kind AS company_type
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    EXISTS (
        SELECT 1 
        FROM TopActors ta 
        WHERE ta.actor_name = ak.name 
        AND ta.rank <= 10
    )
ORDER BY 
    t.production_year DESC, 
    ak.name ASC, 
    t.title ASC;
