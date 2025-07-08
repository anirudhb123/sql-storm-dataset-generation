
WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL 
        AND t.production_year BETWEEN 2000 AND 2023
),
PopularActors AS (
    SELECT 
        actor_name, 
        COUNT(*) AS movie_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
ActorMovies AS (
    SELECT 
        ra.actor_name,
        ra.movie_title,
        ra.production_year,
        t.kind_id,
        ki.keyword
    FROM 
        RankedTitles ra
    JOIN 
        title t ON ra.movie_title = t.title
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        ra.actor_name IN (SELECT actor_name FROM PopularActors)
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    ct.kind AS movie_kind,
    LISTAGG(DISTINCT am.keyword, ', ') WITHIN GROUP (ORDER BY am.keyword) AS keywords
FROM 
    ActorMovies am
JOIN 
    kind_type ct ON am.kind_id = ct.id
GROUP BY 
    am.actor_name, am.movie_title, am.production_year, ct.kind
ORDER BY 
    am.production_year DESC, am.actor_name;
