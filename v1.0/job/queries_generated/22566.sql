WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END) AS valid_roles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN 
        RankedTitles rt ON at.id = rt.title_id AND rt.rn <= 3
    GROUP BY 
        a.id, a.name
), 
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
MovieInfoOrder AS (
    SELECT 
        mi.movie_id,
        mi.info,
        ROW_NUMBER() OVER (PARTITION BY mi.info_type_id ORDER BY mi.note) AS info_order
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
)

SELECT 
    ar.actor_id,
    ar.name AS actor_name,
    ar.movie_count,
    ar.titles,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    mi.info AS movie_info,
    mi.info_order,
    CASE 
        WHEN ar.valid_roles > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS actor_status
FROM 
    ActorRoles ar
LEFT JOIN 
    title m ON ar.movie_count > 1 AND m.production_year IS NOT NULL
LEFT JOIN 
    TitleKeywords tk ON m.id = tk.movie_id
LEFT JOIN 
    MovieInfoOrder mi ON m.id = mi.movie_id AND mi.info_order <= 2
WHERE 
    (ar.movie_count > 0 OR (ar.valid_roles IS NULL AND ar.titles IS NOT NULL))
ORDER BY 
    ar.movie_count DESC, ar.name;


