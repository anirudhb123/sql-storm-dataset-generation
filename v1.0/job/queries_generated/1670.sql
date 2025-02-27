WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.count DESC) AS rank,
        b.count AS cast_count
    FROM 
        aka_title a
    JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS count
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) b ON a.id = b.movie_id
), PopularActors AS (
    SELECT 
        ak.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(c.movie_id) > 5
), MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        n.name AS company_name,
        r.role AS actor_role
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name n ON mc.company_id = n.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(pa.name, 'Unknown Actor') AS popular_actor,
    md.keyword,
    md.company_name,
    md.actor_role,
    rm.rank,
    rm.cast_count
FROM 
    MovieDetails md
LEFT JOIN 
    PopularActors pa ON md.actor_role = pa.name
JOIN 
    RankedMovies rm ON md.title = rm.title AND md.production_year = rm.production_year
WHERE 
    md.production_year >= 2000
ORDER BY 
    rm.rank, md.title;
