WITH DetailedCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.type AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords_list,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.person_role_id = r.id
    JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id
    GROUP BY 
        ci.movie_id, a.name, r.role, c.type
),
RankedMovies AS (
    SELECT 
        movie_id,
        actor_name,
        role_name,
        company_type,
        company_count,
        keywords_list,
        info_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY company_count DESC, info_count DESC) AS rank
    FROM 
        DetailedCast
)
SELECT 
    r.movie_id,
    r.actor_name,
    r.role_name,
    r.company_type,
    r.company_count,
    r.keywords_list,
    r.info_count
FROM 
    RankedMovies r
WHERE 
    r.rank = 1
ORDER BY 
    r.movie_id, r.actor_name;
