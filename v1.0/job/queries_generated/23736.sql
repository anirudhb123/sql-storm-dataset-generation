WITH RECURSIVE ActorChain AS (
    SELECT 
        ai.person_id,
        ak.name AS actor_name,
        ct.kind AS role,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    UNION ALL
    SELECT 
        ac.person_id,
        ak.name AS actor_name,
        ct.kind AS role,
        ac.level + 1
    FROM 
        ActorChain ac
    JOIN 
        cast_info ci ON ac.person_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year < 2000)
)
, MovieKeywordCount AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title at ON mk.movie_id = at.id
    GROUP BY 
        mi.movie_id
)
, RankedTitles AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        at.id, at.title, at.production_year
)

SELECT 
    at.title AS movie_title,
    ac.actor_name,
    ac.role,
    r.rank,
    mkc.keyword_count
FROM 
    RankedTitles r
JOIN 
    ActorChain ac ON r.movie_id = ac.person_id
JOIN 
    MovieKeywordCount mkc ON mkc.movie_id = r.movie_id
WHERE 
    r.rank <= 5
AND 
    ac.level < 3
ORDER BY 
    mkc.keyword_count DESC, ac.actor_name;
