
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS level,
        m.episode_of_id
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1,
        m.episode_of_id
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.movie_id,
        ak.name AS actor_name,
        ak.name_pcode_cf,
        ak.name_pcode_nf,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY a.nr_order) AS actor_order
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(ad.actor_name, 'No Actors') AS first_actor,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorDetails ad ON mh.movie_id = ad.movie_id AND ad.actor_order = 1
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)

SELECT 
    cmd.movie_title,
    cmd.production_year,
    cmd.first_actor,
    cmd.keywords,
    COUNT(DISTINCT ac.id) AS distinct_complete_cast
FROM 
    CompleteMovieDetails cmd
LEFT JOIN 
    complete_cast ac ON cmd.movie_id = ac.movie_id
WHERE 
    cmd.production_year > 2005
GROUP BY 
    cmd.movie_title, cmd.production_year, cmd.first_actor, cmd.keywords
ORDER BY 
    cmd.production_year DESC,
    cmd.movie_title ASC;
