WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        r.role,
        COUNT(c.nr_order) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, a.name, c.movie_id, r.role
)
SELECT 
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    ad.role,
    ad.role_count,
    rt.keyword
FROM 
    RankedTitles rt
JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
JOIN 
    ActorDetails ad ON cc.subject_id = ad.actor_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, 
    LENGTH(rt.title) DESC, 
    ad.role_count DESC;
