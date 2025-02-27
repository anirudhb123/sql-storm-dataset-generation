WITH RecursiveMovieActors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    WHERE 
        ca.note IS NULL OR ca.note NOT LIKE '%uncredited%'
),
MoviesWithKeywords AS (
    SELECT 
        mt.title,
        mt.production_year,
        mk.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.title, mt.production_year, mk.keyword
),
ActorsWithMultipleRoles AS (
    SELECT 
        cm.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ca.role_id) AS role_count
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        complete_cast cm ON ca.movie_id = cm.movie_id
    GROUP BY 
        cm.movie_id, ak.name
    HAVING 
        COUNT(DISTINCT ca.role_id) > 1
),
MoviesWithPopularity AS (
    SELECT 
        mt.id,
        mt.title,
        COALESCE(SUM(ci.nr_order), 0) AS total_appearances
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id
),
MostPopularTitle AS (
    SELECT 
        title, 
        total_appearances,
        RANK() OVER (ORDER BY total_appearances DESC) AS popularity_rank
    FROM 
        MoviesWithPopularity
)
SELECT 
    mw.title,
    mw.production_year,
    rma.actor_name,
    mwt.keyword,
    mp.popularity_rank
FROM 
    MoviesWithKeywords mwt
JOIN 
    MoviesWithPopularity mw ON mw.id = mwt.movie_id
LEFT JOIN 
    RecursiveMovieActors rma ON rma.movie_id = mw.id AND rma.actor_rank <= 3
LEFT JOIN 
    MostPopularTitle mp ON mw.title = mp.title
WHERE 
    mwt.keyword LIKE '%action%'
    OR mwt.keyword IS NULL
ORDER BY 
    mw.production_year DESC, 
    mp.popularity_rank ASC, 
    rma.actor_name ASC;
