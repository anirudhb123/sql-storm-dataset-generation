WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        c.kind_id,
        COALESCE(t.production_year, 1900) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        kind_type k ON t.kind_id = k.id
    WHERE 
        t.production_year IS NOT NULL OR t.production_year IS NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT ct.kind) FILTER (WHERE ct.kind IS NOT NULL) AS roles,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
    GROUP BY 
        ci.movie_id, a.name
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cd.total_actors, 0) AS total_actors,
        CASE WHEN mh.production_year = 1900 THEN 'Unknown Year' ELSE mh.production_year::text END AS production_year_label,
        STRING_AGG(DISTINCT cd.actor_name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
FinalResult AS (
    SELECT 
        ms.title,
        ms.production_year_label,
        ms.total_actors,
        CASE 
            WHEN ms.total_actors = 0 THEN 'No Actors'
            WHEN ms.total_actors <= 5 THEN 'Few Actors'
            WHEN ms.total_actors <= 15 THEN 'Moderate Cast'
            ELSE 'Large Cast'
        END AS cast_size_category,
        ROW_NUMBER() OVER (ORDER BY ms.total_actors DESC) AS rank
    FROM 
        MovieStats ms
    WHERE 
        ms.production_year IS NOT NULL
)
SELECT 
    fr.title,
    fr.production_year_label,
    fr.total_actors,
    fr.cast_size_category
FROM 
    FinalResult fr
WHERE 
    fr.rank <= 10
ORDER BY 
    fr.total_actors DESC NULLS LAST;
