WITH RECURSIVE MovieHierarchy AS (
    -- CTE to build a hierarchy of movies and their linked movies
    SELECT 
        ml.movie_id AS original_movie,
        ml.linked_movie_id AS linked_movie,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') -- only interested in sequels

    UNION ALL

    SELECT 
        mh.original_movie,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie = ml.movie_id 
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),

-- CTE to get the detailed information of all relevant movies
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        k.keyword AS associated_keyword,
        COALESCE(mt.note, 'No note') AS movie_note
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mt ON m.id = mt.movie_id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'Trivia')
    WHERE 
        m.production_year >= 2000 -- filter for movies made after 2000
),

-- CTE to gather cast information for the listed movies
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
)

-- Final query combining all CTEs with outer joins to get comprehensive results
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.associated_keyword,
    cd.cast_count,
    cd.actor_names,
    mh.level AS sequel_level,
    COALESCE(gb.budget, 'No budget info') AS budget_info     
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    MovieHierarchy mh ON md.movie_id = mh.original_movie
LEFT JOIN 
    (SELECT movie_id, info FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')) gb 
ON 
    md.movie_id = gb.movie_id
WHERE 
    md.associated_keyword IS NOT NULL -- ensure we only consider movies with associated keywords
ORDER BY 
    md.production_year DESC, 
    cd.cast_count DESC;
