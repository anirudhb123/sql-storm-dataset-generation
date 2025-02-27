WITH RecursiveMovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        rm.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN RecursiveMovieHierarchy rm ON ml.movie_id = rm.movie_id
),
RankedActors AS (
    SELECT 
        ka.id AS actor_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (PARTITION BY ka.id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    GROUP BY ka.id
),
MoviesWithKeywords AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS notes_count
    FROM aka_title at
    LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON at.id = mi.movie_id
    GROUP BY at.id
),
FilteredMovies AS (
    SELECT 
        m.title,
        m.production_year,
        mk.keywords,
        ak.actor_count,
        mh.level AS hierarchy_level
    FROM RecursiveMovieHierarchy mh
    JOIN MoviesWithKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS actor_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ) ak ON mh.movie_id = ak.movie_id
    WHERE mh.level <= 2
),
ActorPerformance AS (
    SELECT 
        ra.name AS actor_name,
        f.title AS movie_title,
        f.production_year,
        f.keywords,
        f.hierarchy_level,
        (SELECT COUNT(DISTINCT ci2.id) 
         FROM cast_info ci2 
         WHERE ci2.movie_id IN (SELECT movie_id FROM FilteredMovies) 
         AND ci2.person_id = ra.actor_id) AS movies_with_sibling_links
    FROM RankedActors ra
    JOIN FilteredMovies f ON ra.actor_rank <= 5
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords,
    hierarchy_level,
    movies_with_sibling_links,
    CASE 
        WHEN hierarchy_level = 0 THEN 'Original'
        WHEN hierarchy_level = 1 THEN 'Linked'
        ELSE 'Extended'
    END AS movie_type
FROM ActorPerformance
ORDER BY production_year DESC, actor_name;
