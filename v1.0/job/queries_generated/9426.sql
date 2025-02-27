WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        ak.title AS movie_title,
        ak.production_year,
        c.nr_order,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY ak.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title ak ON c.movie_id = ak.movie_id
    JOIN role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rt.title AS title,
    rt.production_year,
    ad.actor_name,
    ad.role,
    mk.keywords
FROM RankedTitles rt
JOIN ActorDetails ad ON rt.title_id = ad.movie_title AND ad.actor_rank <= 3
LEFT JOIN MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE rt.rn <= 10
ORDER BY rt.production_year DESC, ad.actor_rank;
