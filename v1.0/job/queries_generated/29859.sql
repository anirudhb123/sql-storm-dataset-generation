WITH ActorTitles AS (
    SELECT 
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        at.kind_id
    FROM 
        aka_name AS ka
    JOIN 
        cast_info AS ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title AS at ON ci.movie_id = at.movie_id
), TitleKeywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        aka_title AS mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.id, mt.title
), ActorInfo AS (
    SELECT 
        pi.person_id,
        GROUP_CONCAT(DISTINCT pi.info) AS person_details
    FROM 
        person_info AS pi
    GROUP BY 
        pi.person_id
), MoviesWithKeywords AS (
    SELECT 
        at.actor_name,
        at.movie_title,
        at.production_year,
        tk.keywords
    FROM 
        ActorTitles AS at
    LEFT JOIN 
        TitleKeywords AS tk ON at.movie_title = tk.title
), RankedMovies AS (
    SELECT 
        mwk.actor_name,
        mwk.movie_title,
        mwk.production_year,
        mwk.keywords,
        ROW_NUMBER() OVER(PARTITION BY mwk.actor_name ORDER BY mwk.production_year DESC) AS rank
    FROM 
        MoviesWithKeywords AS mwk
)
SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    rm.keywords,
    ai.person_details
FROM 
    RankedMovies AS rm
LEFT JOIN 
    ActorInfo AS ai ON rm.actor_name = ai.person_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.actor_name,
    rm.production_year DESC;
