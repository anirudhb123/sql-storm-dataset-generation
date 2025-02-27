WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_kind
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
TitleInfo AS (
    SELECT 
        t.title,
        t.production_year,
        kt.kind AS kind,
        ti.info AS additional_info
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type ti ON mi.info_type_id = ti.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    rt.title,
    rt.production_year,
    rt.actor_count,
    rt.actors,
    ti.kind,
    ti.additional_info
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleInfo ti ON rt.title = ti.title
WHERE 
    rt.rank_within_kind <= 5
ORDER BY 
    rt.kind_id, rt.actor_count DESC;