WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorInfo AS (
    SELECT 
        a.person_id,
        CONCAT(ak.name, ' (', pt.role, ')') AS actor_role,
        ARRAY_AGG(DISTINCT mi.movie_id) AS movies
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
    JOIN 
        role_type pt ON a.person_role_id = pt.id    
    JOIN 
        complete_cast cc ON cc.subject_id = ak.person_id
    JOIN 
        MovieInfo mi ON mi.movie_id = cc.movie_id
    GROUP BY 
        a.person_id, ak.name, pt.role
),
FinalSelect AS (
    SELECT
        ai.person_id,
        ai.actor_role,
        COUNT(DISTINCT mi.movie_id) AS total_movies,
        STRING_AGG(DISTINCT mi.title || ' (' || mi.production_year || ')', '; ') AS movie_list
    FROM 
        ActorInfo ai
    JOIN 
        MovieInfo mi ON ai.movies @> ARRAY[mi.movie_id]
    GROUP BY 
        ai.person_id, ai.actor_role
)
SELECT 
    fs.actor_role,
    fs.total_movies,
    fs.movie_list
FROM 
    FinalSelect fs
ORDER BY 
    fs.total_movies DESC;
