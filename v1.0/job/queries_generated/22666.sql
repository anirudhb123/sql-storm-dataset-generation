WITH RecursiveActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        ak.name AS actor_name,
        c.movie_id,
        ct.kind AS role_kind,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        comp_cast_type ct ON ct.id = c.person_role_id
    JOIN 
        title t ON t.id = c.movie_id
    WHERE 
        t.production_year > 2000
),
MovieYears AS (
    SELECT 
        m.id AS movie_id,
        m.production_year,
        COUNT(DISTINCT pause_id) AS total_actors
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    GROUP BY 
        m.id, m.production_year
),
ParticularKeywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ma.actor_name,
    mv.title,
    mv.production_year,
    mv.total_actors,
    pk.keywords,
    CASE 
        WHEN ma.role_rank IS NULL THEN 'No Role'
        ELSE ma.role_kind
    END AS role_type,
    COALESCE(pm.info, 'N/A') AS personal_info,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies,
    MAX(CASE 
        WHEN m.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END) AS era
FROM 
    RecursiveActorRoles ma
JOIN 
    MovieYears mv ON mv.movie_id = ma.movie_id
LEFT JOIN 
    ParticularKeywords pk ON pk.movie_id = ma.movie_id
LEFT JOIN 
    person_info pm ON pm.person_id = ma.person_id AND pm.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
LEFT JOIN 
    movie_link ml ON ml.movie_id = ma.movie_id
WHERE 
    mv.total_actors > 5
GROUP BY 
    ma.actor_name, mv.title, mv.production_year, mv.total_actors, pk.keywords, ma.role_rank, pm.info
ORDER BY 
    mv.production_year DESC, ma.actor_name ASC;
