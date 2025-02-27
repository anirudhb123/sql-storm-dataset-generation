WITH RecursiveActorMovies AS (
    SELECT 
        c.person_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order IS NOT NULL
),
AggregatedRoleCounts AS (
    SELECT 
        person_id,
        COUNT(DISTINCT c.role_id) AS distinct_role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        person_id
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.company_id) AS company_count
    FROM 
        movie_companies m
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        mc.movie_id
),
KeyedMovieTitles AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
LatestActors AS (
    SELECT 
        r.person_id,
        r.movie_title,
        r.production_year,
        a.name AS actor_name
    FROM 
        RecursiveActorMovies r
    JOIN 
        aka_name a ON r.person_id = a.person_id
    WHERE 
        r.movie_rank = 1
)
SELECT 
    la.actor_name,
    la.movie_title,
    la.production_year,
    COALESCE(arc.distinct_role_count, 0) AS role_count,
    COALESCE(kmt.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(cmc.company_count, 1) AS associated_company_count
FROM 
    LatestActors la
LEFT JOIN 
    AggregatedRoleCounts arc ON la.person_id = arc.person_id
LEFT JOIN 
    KeyedMovieTitles kmt ON la.movie_title = kmt.movie_id
LEFT JOIN 
    CompanyMovieCount cmc ON la.movie_title = cmc.movie_id
WHERE 
    la.production_year IS NOT NULL
ORDER BY 
    la.production_year DESC, 
    la.actor_name ASC;
