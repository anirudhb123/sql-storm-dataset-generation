WITH recursive movie_list AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        tn.info AS title_note,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info ti ON t.id = ti.movie_id
    LEFT JOIN 
        info_type it ON ti.info_type_id = it.id
    WHERE 
        it.info ILIKE '%Oscars%'
),
cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ct.kind AS role,
        CASE 
            WHEN ci.note IS NOT NULL THEN ci.note
            ELSE 'N/A' 
        END AS cast_note
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id 
),
keyword_aggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_output AS (
    SELECT 
        ml.movie_id,
        ml.title,
        ml.production_year,
        ml.title_note,
        cd.actor_name,
        cd.role,
        cd.cast_note,
        ka.keywords
    FROM 
        movie_list ml
    LEFT JOIN 
        cast_details cd ON ml.movie_id = cd.movie_id
    LEFT JOIN 
        keyword_aggregation ka ON ml.movie_id = ka.movie_id
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    COALESCE(fo.title_note, 'No Note Available') AS title_note,
    COALESCE(fo.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(fo.role, 'Unspecified Role') AS role,
    CASE 
        WHEN fo.cast_note = 'N/A' THEN 'No Notation'
        ELSE fo.cast_note 
    END AS cast_note,
    CASE 
        WHEN fo.keywords IS NOT NULL THEN fo.keywords
        ELSE 'No Keywords Associated' 
    END AS keywords
FROM 
    final_output fo
WHERE 
    fo.production_year > 2000
ORDER BY 
    fo.production_year DESC, fo.movie_id
LIMIT 100;
