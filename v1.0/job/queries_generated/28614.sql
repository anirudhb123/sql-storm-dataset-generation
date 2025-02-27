WITH RankedActors AS (
    SELECT 
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY c.nr_order) AS rank_order,
        t.production_year,
        t.title AS movie_title,
        t.kind_id,
        k.keyword AS movie_keyword,
        ci.kind AS company_type,
        COUNT(DISTINCT cm.company_id) AS total_companies
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ci ON mc.company_type_id = ci.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        ak.name, ak.person_id, t.production_year, t.title, t.kind_id, k.keyword, ci.kind
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        RankedActors
    WHERE 
        rank_order = 1
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    ra.actor_name,
    ra.movie_title,
    ra.production_year,
    ra.movie_keyword,
    ra.total_companies
FROM 
    RankedActors ra
JOIN 
    TopActors ta ON ra.actor_name = ta.actor_name
ORDER BY 
    ra.production_year DESC, ra.movie_title;
