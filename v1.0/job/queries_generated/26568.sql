WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS title_rank
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%action%'
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        t.title,
        c.nr_order,
        r.role AS role_description,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY c.nr_order) AS actor_role_rank
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN role_type r ON c.role_id = r.id
    WHERE c.nr_order IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title) AS title_count
    FROM ActorRoles
    WHERE actor_role_rank <= 3
    GROUP BY actor_name
    HAVING COUNT(DISTINCT title) > 5
),
MoviesWithTopActors AS (
    SELECT 
        t.title,
        t.production_year,
        a.actor_name,
        a.title_count
    FROM TopActors a
    JOIN ActorRoles r ON a.actor_name = r.actor_name
    JOIN title t ON r.title = t.title
)
SELECT 
    m.title,
    m.production_year,
    m.actor_name,
    m.title_count,
    CASE 
        WHEN m.title_count >= 10 THEN 'Superstar'
        WHEN m.title_count >= 5 THEN 'Seasoned Actor'
        ELSE 'Emerging Talent'
    END AS actor_category
FROM MoviesWithTopActors m
ORDER BY m.title_count DESC, m.production_year DESC;
