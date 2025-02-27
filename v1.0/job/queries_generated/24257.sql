WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        t.kind_id,
        COALESCE(kt.keyword, 'Unknown') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id,
        m.title,
        m.production_year,
        t.kind_id,
        COALESCE(kt.keyword, 'Unknown') AS keyword
    FROM 
        movie_link mc
    JOIN 
        aka_title m ON mc.linked_movie_id = m.id
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        mc.movie_id IN (SELECT movie_id FROM MovieHierarchy)
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.person_id END) AS cast_with_notes
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FinalReport AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year, 
        mh.kind_id,
        mh.keyword,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.cast_with_notes, 0) AS cast_with_notes,
        ROW_NUMBER() OVER (PARTITION BY mh.keyword ORDER BY mh.production_year DESC) AS rank_by_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStatistics cs ON mh.movie_id = cs.movie_id
)

SELECT 
    title,
    production_year,
    kind_id,
    keyword,
    total_cast,
    cast_with_notes,
    CASE 
        WHEN total_cast - cast_with_notes > 0 THEN 'Notable'
        ELSE 'Complete'
    END AS cast_status
FROM 
    FinalReport
WHERE 
    EXISTS (
        SELECT 1 FROM aka_name an 
        WHERE an.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = FinalReport.movie_id)
    )
AND 
    keyword IS NOT NULL
AND 
    NOT EXISTS (
        SELECT 1 FROM movie_info mi 
        WHERE mi.movie_id = FinalReport.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Trivia')
        AND mi.info IS NULL
    )
ORDER BY 
    rank_by_year, title;
