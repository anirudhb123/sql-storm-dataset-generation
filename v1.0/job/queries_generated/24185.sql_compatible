
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL 
        AND m.title IS NOT NULL
),
GenreCounts AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        movie_companies AS mc ON mk.movie_id = mc.movie_id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        k.id, k.keyword
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movies_joined
    FROM 
        aka_name AS a
    LEFT JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(ci.movie_id) > 10
),
CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name,
        ct.kind AS company_type
    FROM 
        company_name AS c
    LEFT JOIN 
        movie_companies AS mc ON c.id = mc.company_id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        mc.movie_id IS NULL
    ORDER BY 
        c.name
),
MaxProductionYear AS (
    SELECT 
        DISTINCT ON (kind_id) kind_id,
        production_year
    FROM 
        aka_title
    WHERE 
        production_year IS NOT NULL
    ORDER BY kind_id, production_year DESC
)
SELECT 
    R.movie_id,
    R.title,
    COALESCE(AG.actor_count, 0) AS actor_count,
    GC.movie_count AS genre_movie_count,
    C.company_id,
    C.name AS company_name,
    C.company_type,
    COALESCE(MPY.production_year::text, 'No Entries') AS last_production_year
FROM 
    RankedMovies R
LEFT JOIN (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) AG ON R.movie_id = AG.movie_id
LEFT JOIN GenreCounts GC ON R.kind_id = GC.keyword_id
LEFT JOIN CompanyInfo C ON R.movie_id = C.company_id
LEFT JOIN MaxProductionYear MPY ON R.kind_id = MPY.kind_id
WHERE 
    R.rank <= 5
ORDER BY 
    R.production_year DESC, 
    R.title ASC;
