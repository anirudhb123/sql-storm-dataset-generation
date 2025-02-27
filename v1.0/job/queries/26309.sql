
WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        c.role_id,
        c.nr_order,
        ci.kind AS character_type,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id 
    JOIN 
        aka_name ak ON c.person_id = ak.person_id 
    JOIN 
        role_type rt ON c.role_id = rt.id 
    JOIN 
        complete_cast cc ON cc.movie_id = mt.id AND cc.subject_id = c.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.id 
    JOIN 
        keyword kw ON kw.id = mk.keyword_id
    JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        mt.production_year > 2000 
        AND ak.name LIKE 'A%'
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name, c.role_id, c.nr_order, ci.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.role_id,
    md.nr_order,
    md.character_type,
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.nr_order ASC;
