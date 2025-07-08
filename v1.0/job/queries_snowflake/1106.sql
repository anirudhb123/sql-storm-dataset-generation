
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        MAX(CASE 
                WHEN ci.note IS NOT NULL THEN 1 
                ELSE 0 
            END) AS has_note
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ct.id = ci.person_role_id
    GROUP BY 
        ci.movie_id, ak.name, ct.kind
), 
info_with_keywords AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mk.movie_id = mi.movie_id
    JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role_type,
    cd.total_actors,
    iwk.keywords,
    CASE 
        WHEN cd.has_note = 1 THEN 'Note Present' 
        ELSE 'No Note' 
    END AS note_status
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    info_with_keywords iwk ON rm.movie_id = iwk.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, cd.total_actors DESC NULLS LAST;
